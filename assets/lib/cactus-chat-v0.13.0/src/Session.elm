port module Session exposing
    ( Error(..)
    , Kind(..)
    , Session
    , authenticatedRequest
    , decodeStoredSession
    , getHomeserverUrl
    , getUserId
    , incrementTransactionId
    , isUser
    , login
    , registerGuest
    , sessionKind
    , storeSessionCmd
    , transactionId
    )

import ApiUtils exposing (clientEndpoint)
import Http
import Json.Decode as JD
import Json.Encode as JE
import Process
import Task exposing (Task)
import Url.Builder exposing (QueryParameter)



{- This module contains the UI and API interactions for logging in using temporary guest accounts or
   existing accounts on arbitrary Matrix homeservers using the Client-Server API.
-}


{-| Opaque type for an authenticated Matrix session.
-}
type Session
    = Session SessionData


type alias SessionData =
    { homeserverUrl : String
    , kind : Kind
    , txnId : Int
    , userId : String
    , accessToken : String
    }


getHomeserverUrl : Session -> String
getHomeserverUrl (Session session) =
    session.homeserverUrl


{-| Decodes "user\_id" and "access\_token" fields into a Session record.
Can be used for both /register and /login.
-}
decodeSession : String -> Kind -> JD.Decoder Session
decodeSession homeserverUrl kind =
    JD.map2 (SessionData homeserverUrl kind 0)
        (JD.field "user_id" JD.string)
        (JD.field "access_token" JD.string)
        |> JD.map Session


getUserId : Session -> String
getUserId (Session session) =
    session.userId



-- TRANSACTION ID


{-| Increment the transaction id of this session.
Should be incremented on each message sent.
-}
incrementTransactionId : Session -> Session
incrementTransactionId (Session session) =
    Session { session | txnId = session.txnId + 1 }


{-| Get the current transaction Id
-}
transactionId : Session -> Int
transactionId (Session session) =
    session.txnId



-- KIND


type Kind
    = Guest
    | User


sessionKind : Session -> Kind
sessionKind (Session session) =
    session.kind


isUser : Session -> Bool
isUser (Session session) =
    session.kind == User


toString : Kind -> String
toString authType =
    case authType of
        Guest ->
            "guest"

        User ->
            "user"


decodeKind : JD.Decoder Kind
decodeKind =
    JD.string
        |> JD.andThen
            (\kind ->
                case kind of
                    "guest" ->
                        JD.succeed Guest

                    "user" ->
                        JD.succeed User

                    _ ->
                        JD.fail <| kind ++ " is not a valid Session.Kind"
            )



-- API CALLS


{-| Make authenticated requests using a Session object.
Wraps `apiRequest`, adding Authorization headers.
-}
authenticatedRequest :
    Session
    ->
        { method : String
        , path : List String
        , params : List QueryParameter
        , body : Http.Body
        , responseDecoder : JD.Decoder a
        }
    -> Task Error a
authenticatedRequest (Session session) { method, path, params, body, responseDecoder } =
    apiRequest
        { method = method
        , url = clientEndpoint session.homeserverUrl path params
        , body = body
        , accessToken = Just session.accessToken
        , responseDecoder = responseDecoder
        }


{-| Make unauthenticated requests to a Matrix API
-}
unauthenticatedRequest : { method : String, url : String, body : Http.Body, responseDecoder : JD.Decoder a } -> Task Error a
unauthenticatedRequest { method, url, body, responseDecoder } =
    apiRequest
        { method = method
        , url = url
        , body = body
        , responseDecoder = responseDecoder
        , accessToken = Nothing
        }


{-| Make an optionally authenticated requests to a Matrix homeserver.
Retry on network failure.
-}
apiRequest :
    { method : String
    , url : String
    , accessToken : Maybe String
    , responseDecoder : JD.Decoder a
    , body : Http.Body
    }
    -> Task Error a
apiRequest { method, url, accessToken, responseDecoder, body } =
    let
        request : Task Error_ a
        request =
            Http.task
                { method = method
                , headers =
                    accessToken
                        |> Maybe.map (\at -> [ Http.header "Authorization" <| "Bearer " ++ at ])
                        |> Maybe.withDefault []
                , url = url
                , body = body
                , resolver = Http.stringResolver <| handleJsonResponse responseDecoder
                , timeout = Nothing
                }
    in
    request |> Task.onError (onError request)



-- ERRORS


type Error
    = Error String String


type Error_
    = UnhandledError String String
    | RetryAfterMs Int


onError : Task Error_ a -> Error_ -> Task Error a
onError request error =
    case error of
        UnhandledError errcode err ->
            Task.fail <| Error errcode err

        RetryAfterMs ms ->
            Process.sleep (toFloat ms)
                |> Task.andThen
                    (\() ->
                        request
                            |> Task.onError (onError request)
                    )


retryConstant : Int
retryConstant =
    30


{-| handle the JSON response of a HTTP Request
Flatten HTTP and JSON errors.
Parse Matrix "standard error responses".
-}
handleJsonResponse : JD.Decoder a -> Http.Response String -> Result Error_ a
handleJsonResponse decoder response =
    case response of
        Http.BadUrl_ url ->
            Err <| UnhandledError "Bad url" url

        Http.Timeout_ ->
            Err <| RetryAfterMs retryConstant

        Http.NetworkError_ ->
            Err <| RetryAfterMs retryConstant

        Http.BadStatus_ _ body ->
            Err <|
                (JD.decodeString decodeMatrixError body
                    |> Result.withDefault (UnhandledError "Could not decode error" body)
                )

        Http.GoodStatus_ _ body ->
            case JD.decodeString decoder body of
                Err _ ->
                    Err <| UnhandledError "Could not decode response" body

                Ok result ->
                    Ok result


decodeMatrixError : JD.Decoder Error_
decodeMatrixError =
    JD.map2 Tuple.pair
        (JD.field "errcode" JD.string)
        (JD.field "error" JD.string)
        |> JD.andThen
            (\( errcode, error ) ->
                case errcode of
                    "M_LIMIT_EXCEEDED" ->
                        JD.oneOf
                            [ JD.map RetryAfterMs <| JD.field "retry_after_ms" JD.int
                            , JD.succeed <| UnhandledError errcode error
                            ]

                    _ ->
                        JD.succeed <| UnhandledError errcode error
            )



-- AUTHENTICATION


{-| Register a guest account with the homeserver, by sending a HTTP POST to
/register?kind=guest. This presumes that the homeserver has enabled guest registrations.
-}
registerGuest : String -> Task Error Session
registerGuest homeserverUrl =
    unauthenticatedRequest
        { method = "POST"
        , url = clientEndpoint homeserverUrl [ "register" ] [ Url.Builder.string "kind" "guest" ]
        , responseDecoder = decodeSession homeserverUrl Guest
        , body = Http.stringBody "application/json" "{}"
        }


{-| Login by sending a POST request to the /login endpoint
Login type "m.login.password" and identifier type "m.id.user"
-}
login : { homeserverUrl : String, user : String, password : String } -> Task Error Session
login { homeserverUrl, user, password } =
    unauthenticatedRequest
        { method = "POST"
        , url = clientEndpoint homeserverUrl [ "login" ] []
        , responseDecoder = decodeSession homeserverUrl User
        , body = Http.jsonBody <| passwordLoginJson { user = user, password = password }
        }


{-| Make JSON Value for logging in using /login
Login type "m.login.password" and identifier type "m.id.user"
As described in the Client Server spec:
<https://matrix.org/docs/spec/client_server/r0.6.1#post-matrix-client-r0-login>
-}
passwordLoginJson : { user : String, password : String } -> JE.Value
passwordLoginJson { user, password } =
    JE.object
        [ ( "type", JE.string "m.login.password" )
        , ( "identifier"
          , JE.object
                [ ( "type", JE.string "m.id.user" )
                , ( "user", JE.string user )
                ]
          )
        , ( "password", JE.string password )
        , ( "initial_device_display_name", JE.string "Cactus Comments" )
        ]



-- PERSISTENCE


port storeSession : String -> Cmd msg


storeSessionCmd : Session -> Cmd msg
storeSessionCmd session =
    encodeStoredSession session |> storeSession


encodeStoredSession : Session -> String
encodeStoredSession (Session { homeserverUrl, kind, txnId, userId, accessToken }) =
    JE.object
        [ ( "homeserverUrl", JE.string homeserverUrl )
        , ( "kind", JE.string <| toString kind )
        , ( "txnId", JE.int txnId )
        , ( "userId", JE.string userId )
        , ( "accessToken", JE.string accessToken )
        ]
        |> JE.encode 0


decodeStoredSession : JD.Decoder Session
decodeStoredSession =
    JD.map Session <|
        JD.map5 SessionData
            (JD.field "homeserverUrl" JD.string)
            (JD.field "kind" decodeKind)
            (JD.field "txnId" JD.int)
            (JD.field "userId" JD.string)
            (JD.field "accessToken" JD.string)
