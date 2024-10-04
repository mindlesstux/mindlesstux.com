module Event exposing (Event, GetMessagesResponse, RoomEvent(..), decodePaginatedEvents, latestMemberDataBefore, messageEvents)

import Json.Decode as JD
import Member exposing (MemberData, decodeMember)
import Message exposing (Message, decodeMessage)
import Time


type RoomEvent
    = MessageEvent (Event Message)
    | MemberEvent String (Event MemberData)
    | UnsupportedEvent (Event ())


type alias Event a =
    { eventType : String
    , content : a
    , sender : String
    , originServerTs : Time.Posix
    }


type alias GetMessagesResponse =
    { start : String
    , end : Maybe String
    , chunk : List RoomEvent
    }


messageEvents : List RoomEvent -> List (Event Message)
messageEvents roomEvents =
    -- filter room events for message events
    List.foldl
        (\roomEvent msgs ->
            case roomEvent of
                MessageEvent msg ->
                    msg :: msgs

                _ ->
                    msgs
        )
        []
        roomEvents


memberEvents : List RoomEvent -> List ( String, Event MemberData )
memberEvents roomEvents =
    -- filter room events for state events
    List.foldl
        (\roomEvent xs ->
            case roomEvent of
                MemberEvent uid data ->
                    ( uid, data ) :: xs

                _ ->
                    xs
        )
        []
        roomEvents


{-| Get the latest event with `MemberData` that is before a given timestamp.
-}
latestMemberDataBefore : List RoomEvent -> Time.Posix -> String -> Maybe MemberData
latestMemberDataBefore events time userid =
    events
        |> memberEvents
        -- must match userid
        |> List.filter (Tuple.first >> (==) userid)
        -- no longer need userid
        |> List.map Tuple.second
        -- must be before `time`
        |> List.filter (\e -> Time.posixToMillis e.originServerTs <= Time.posixToMillis time)
        -- sort by reversed timestamp
        |> List.sortBy (.originServerTs >> Time.posixToMillis >> (*) -1)
        -- get top result
        |> List.head
        -- only member data
        |> Maybe.map .content


decodePaginatedEvents : JD.Decoder { start : String, end : Maybe String, chunk : List RoomEvent }
decodePaginatedEvents =
    JD.map3
        (\start end chunk -> { start = start, end = end, chunk = chunk })
        (JD.field "start" JD.string)
        (JD.field "end" JD.string |> JD.maybe)
        (JD.field "chunk" <| JD.list decodeRoomEvent)


makeRoomEvent : (String -> a -> String -> Time.Posix -> RoomEvent) -> JD.Decoder a -> JD.Decoder RoomEvent
makeRoomEvent constructor contentDecoder =
    JD.map4
        constructor
        (JD.field "type" JD.string)
        (JD.field "content" contentDecoder)
        (JD.field "sender" JD.string)
        (JD.field "origin_server_ts" JD.int |> JD.map Time.millisToPosix)


decodeRoomEvent : JD.Decoder RoomEvent
decodeRoomEvent =
    JD.oneOf
        [ -- switch on room event type,
          JD.field "type" JD.string
            |> JD.andThen
                (\eventType ->
                    case eventType of
                        "m.room.message" ->
                            makeRoomEvent
                                (\t msg s ots ->
                                    MessageEvent
                                        { eventType = t
                                        , content = msg
                                        , sender = s
                                        , originServerTs = ots
                                        }
                                )
                                decodeMessage

                        "m.room.member" ->
                            JD.field "state_key" JD.string
                                |> JD.andThen
                                    (\uid ->
                                        makeRoomEvent
                                            (\t mdata s ots ->
                                                MemberEvent uid
                                                    { eventType = t
                                                    , content = mdata
                                                    , sender = s
                                                    , originServerTs = ots
                                                    }
                                            )
                                            decodeMember
                                    )

                        _ ->
                            JD.fail ("Unsupported event type: " ++ eventType)
                )

        -- on failure: return unsupported event
        , makeRoomEvent
            (\t msg s ots ->
                UnsupportedEvent
                    { eventType = t
                    , content = msg
                    , sender = s
                    , originServerTs = ots
                    }
            )
            (JD.succeed ())
        ]
