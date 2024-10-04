module Room exposing
    ( Direction(..)
    , Room
    , RoomId
    , commentCount
    , extractRoomId
    , getInitialRoom
    , getNewerMessages
    , getOlderMessages
    , getRoomAsGuest
    , getRoomId
    , joinRoom
    , mergeMessages
    , sendComment
    , viewRoomEvents
    )

import Accessibility exposing (Html, div)
import Dict exposing (Dict)
import Event exposing (GetMessagesResponse, RoomEvent(..), decodePaginatedEvents, latestMemberDataBefore, messageEvents)
import Html.Attributes exposing (class)
import Http
import Json.Decode as JD
import Json.Encode as JE
import Member exposing (MemberData, decodeMember)
import Message exposing (viewMessageEvent)
import Message.Markdown exposing (markdownToHtmlString)
import Session
    exposing
        ( Kind(..)
        , Session
        , authenticatedRequest
        , incrementTransactionId
        , registerGuest
        , sessionKind
        , transactionId
        )
import Task exposing (Task)
import Time
import Url.Builder


type Room
    = Room
        { roomAlias : String
        , roomId : RoomId
        , events : List RoomEvent
        , start : String
        , end : String
        , members : Dict String MemberData
        }


type RoomId
    = RoomId String


{-| Get the roomId field of a room record
-}
extractRoomId : Room -> RoomId
extractRoomId (Room r) =
    r.roomId


{-| Count the number of renderable messages in the room
Used to determine if we should fetch more
-}
commentCount : Room -> Int
commentCount (Room room) =
    List.length <| messageEvents room.events


mergeMessages : Room -> Direction -> { a | start : String, end : Maybe String, chunk : List RoomEvent } -> Room
mergeMessages room dir newMessages =
    case dir of
        Newer ->
            mergeNewerMessages room newMessages

        Older ->
            mergeOlderMessages room newMessages


mergeOlderMessages : Room -> { a | start : String, end : Maybe String, chunk : List RoomEvent } -> Room
mergeOlderMessages (Room room) newMessages =
    Room
        { room
            | events = sortByTime (room.events ++ newMessages.chunk)
            , start = case newMessages.end of
                Nothing ->
                    newMessages.start
                Just end ->
                    end
        }


mergeNewerMessages : Room -> { a | start : String, end : Maybe String, chunk : List RoomEvent } -> Room
mergeNewerMessages (Room room) newMessages =
    Room
        { room
            | events = sortByTime (room.events ++ newMessages.chunk)
            , end = case newMessages.end of
                Nothing ->
                    room.end
                Just end ->
                    end
        }


sortByTime : List RoomEvent -> List RoomEvent
sortByTime events =
    events
        |> List.sortBy
            (\e ->
                case e of
                    MessageEvent msgEvent ->
                        .originServerTs msgEvent |> Time.posixToMillis

                    MemberEvent _ mEvent ->
                        .originServerTs mEvent |> Time.posixToMillis

                    UnsupportedEvent uEvt ->
                        .originServerTs uEvt |> Time.posixToMillis
            )


{-| Register a guest account on the default homeserver, then get a room using
the guest access token.
-}
getRoomAsGuest : { homeserverUrl : String, roomAlias : String } -> Task Session.Error ( Session, Room )
getRoomAsGuest { homeserverUrl, roomAlias } =
    registerGuest homeserverUrl
        |> Task.andThen
            (\session ->
                getInitialRoom session roomAlias
                    |> Task.map (\room -> ( session, room ))
            )


{-| This call chains 3 API requests to set up the room:

1.  Look up roomId using roomAlias
2.  Get message events and pagination tokens
3.  Get current room members

The Task eventually completes a Room record

-}
getInitialRoom : Session -> String -> Task Session.Error Room
getInitialRoom session roomAlias =
    let
        -- find roomId
        addRoomId =
            getRoomId session roomAlias
                |> Task.map
                    (\roomId ->
                        { roomAlias = roomAlias
                        , roomId = roomId
                        }
                    )

        -- get messages from /room/{roomId}/messages
        addEvents data =
            getInitialSync session data.roomId
                |> Task.map
                    (\events ->
                        { roomAlias = data.roomAlias
                        , roomId = data.roomId
                        , --
                          events = sortByTime events.chunk
                        , start = events.start
                        , end = case events.end of
                            Nothing ->
                                events.start
                            Just end ->
                                end
                        }
                    )

        -- get joined members
        addMembers data =
            getJoinedMembers session data.roomId
                |> Task.map
                    (\members ->
                        { roomAlias = data.roomAlias
                        , roomId = data.roomId
                        , events = data.events
                        , start = data.start
                        , end = data.end
                        , --
                          members = members
                        }
                    )
    in
    addRoomId
        |> Task.andThen addEvents
        |> Task.andThen addMembers
        |> Task.map Room


{-| Make a GET request to resolve a roomId from a given roomAlias.
-}
getRoomId : Session -> String -> Task Session.Error RoomId
getRoomId session roomAlias =
    authenticatedRequest
        session
        { method = "GET"
        , path = [ "directory", "room", roomAlias ]
        , params = []
        , responseDecoder = JD.field "room_id" JD.string |> JD.map RoomId
        , body = Http.emptyBody
        }


{-| Get initial room events and sync tokens to get further messages
-}
getInitialSync : Session -> RoomId -> Task Session.Error { chunk : List RoomEvent, start : String, end : Maybe String }
getInitialSync session (RoomId roomId) =
    authenticatedRequest
        session
        { method = "GET"
        , path = [ "rooms", roomId, "initialSync" ]
        , params = []
        , responseDecoder = JD.field "messages" decodePaginatedEvents
        , body = Http.emptyBody
        }


{-| View all of the comments in a Room
The `homeserverUrl` is used translate mxc:// to media API endpoints
-}
viewRoomEvents : String -> Room -> Int -> Time.Posix -> Html msg
viewRoomEvents homeserverUrl (Room room) count now =
    div [ class "cactus-comments-list" ] <|
        List.map
            (\e ->
                let
                    member : Maybe MemberData
                    member =
                        latestMemberDataBefore room.events e.originServerTs e.sender
                            |> Maybe.map Just
                            |> Maybe.withDefault (Dict.get e.sender room.members)
                in
                viewMessageEvent
                    homeserverUrl
                    now
                    e.originServerTs
                    e.sender
                    member
                    e.content
            )
            (messageEvents room.events |> List.take count)



{- API INTERACTIONS -}


type Direction
    = Older
    | Newer


getMessages : Session -> RoomId -> Direction -> String -> Task Session.Error GetMessagesResponse
getMessages session (RoomId roomId) dir from =
    authenticatedRequest
        session
        { method = "GET"
        , path = [ "rooms", roomId, "messages" ]
        , params =
            [ Url.Builder.string "from" from
            , Url.Builder.string "dir" <|
                case dir of
                    Older ->
                        "b"

                    Newer ->
                        "f"
            ]
        , responseDecoder = decodePaginatedEvents
        , body = Http.emptyBody
        }


{-| Get more messages, scanning backwards from the earliest event in the room
-}
getOlderMessages : Session -> Room -> Task Session.Error GetMessagesResponse
getOlderMessages session (Room room) =
    getMessages session room.roomId Older room.start


{-| Get more messages, scanning forwards from the earliest event in the room
-}
getNewerMessages : Session -> Room -> Task Session.Error GetMessagesResponse
getNewerMessages session (Room room) =
    getMessages session room.roomId Newer room.end


joinRoom : Session -> String -> Task Session.Error ()
joinRoom session roomIdOrAlias =
    authenticatedRequest
        session
        { method = "POST"
        , path = [ "join", roomIdOrAlias ]
        , params = []
        , responseDecoder = JD.succeed ()
        , body = Http.stringBody "application/json" "{}"
        }


sendComment : Session -> RoomId -> String -> ( Task Session.Error (), Session )
sendComment session roomId comment =
    ( case sessionKind session of
        Guest ->
            -- join room, send message
            joinAndSend session roomId comment

        User ->
            -- user is already joined, just send message
            sendMessage session roomId comment
      -- increment transaction Id (idempotency measure)
    , incrementTransactionId session
    )


{-| Join a room before sending a comment into the room
-}
joinAndSend : Session -> RoomId -> String -> Task Session.Error ()
joinAndSend session (RoomId roomId) comment =
    joinRoom session roomId
        |> Task.andThen (\_ -> sendMessage session (RoomId roomId) comment)


{-| Send a message to the room.

If the `comment` string is markdown, transform it into a HTML string and send it as `org.matrix.custom.html`.

-}
sendMessage : Session -> RoomId -> String -> Task Session.Error ()
sendMessage session (RoomId roomId) comment =
    -- post a message
    let
        eventType =
            "m.room.message"

        msgtype =
            "m.text"

        formattedBody =
            markdownToHtmlString comment
                |> Maybe.map
                    (\s ->
                        [ ( "format", JE.string "org.matrix.custom.html" )
                        , ( "formatted_body", JE.string s )
                        ]
                    )
                |> Maybe.withDefault []

        txnId =
            transactionId session
    in
    authenticatedRequest
        session
        { method = "PUT"
        , path = [ "rooms", roomId, "send", eventType, String.fromInt txnId ]
        , params = []
        , responseDecoder = JD.succeed ()
        , body =
            Http.jsonBody <|
                JE.object
                    ([ ( "msgtype", JE.string msgtype )
                     , ( "body", JE.string comment )
                     ]
                        ++ formattedBody
                    )
        }


getJoinedMembers : Session -> RoomId -> Task Session.Error (Dict String MemberData)
getJoinedMembers session (RoomId roomId) =
    authenticatedRequest
        session
        { method = "GET"
        , path = [ "rooms", roomId, "members" ]
        , params = []
        , responseDecoder = decodeMemberResponse
        , body = Http.emptyBody
        }


decodeMemberEvent : JD.Decoder ( String, MemberData )
decodeMemberEvent =
    JD.map2 (\s m -> ( s, m ))
        (JD.field "state_key" JD.string)
        (JD.field "content" decodeMember)


decodeMemberResponse : JD.Decoder (Dict String MemberData)
decodeMemberResponse =
    JD.field "chunk"
        (JD.list decodeMemberEvent
            |> JD.andThen (Dict.fromList >> JD.succeed)
        )
