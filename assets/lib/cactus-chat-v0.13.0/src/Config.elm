module Config exposing (StaticConfig, decodeFlags, makeRoomAlias, parseConfig, parseFlags)

import Duration exposing (Duration)
import Json.Decode as JD
import Json.Decode.Pipeline exposing (optional, required)
import Session exposing (Session, decodeStoredSession)


type alias Flags =
    { defaultHomeserverUrl : String
    , serverName : String
    , siteName : String
    , commentSectionId : String
    , storedSession : Maybe Session
    , pageSize : Maybe Int
    , loginEnabled : Maybe Bool
    , guestPostingEnabled : Maybe Bool
    , updateInterval : Maybe Float
    }


type alias StaticConfig =
    { defaultHomeserverUrl : String
    , roomAlias : String
    , pageSize : Int
    , loginEnabled : Bool
    , guestPostingEnabled : Bool
    , updateInterval : Duration
    }


parseConfig : JD.Value -> Result JD.Error ( StaticConfig, Maybe Session )
parseConfig flags =
    flags
        |> JD.decodeValue decodeFlags
        |> Result.map parseFlags


{-| Make a matrix room alias given a sitename, a unique id for the comments
section, and a matrix homeserver servername.

    makeRoomAlias { siteName = "myblog", commentSectionId = "october-blogpost", serverName = "matrix.example.com" }
        == "#comments_myblog.com_october-blogpost:matrix.example.com"

-}
makeRoomAlias : { a | siteName : String, commentSectionId : String, serverName : String } -> String
makeRoomAlias { siteName, commentSectionId, serverName } =
    "#comments_" ++ siteName ++ "_" ++ commentSectionId ++ ":" ++ serverName


parseFlags : Flags -> ( StaticConfig, Maybe Session )
parseFlags flags =
    ( StaticConfig
        flags.defaultHomeserverUrl
        (makeRoomAlias flags)
        (flags.pageSize |> Maybe.withDefault 10)
        (flags.loginEnabled |> Maybe.withDefault True)
        (flags.guestPostingEnabled |> Maybe.withDefault True)
        (flags.updateInterval |> Maybe.withDefault 0 |> Duration.seconds)
    , flags.storedSession
    )


decodeIntOrStr : JD.Decoder (Maybe Int)
decodeIntOrStr =
    JD.oneOf
        [ JD.int |> JD.map Just
        , JD.string |> JD.map String.toInt
        ]


decodeFloatOrStr : JD.Decoder (Maybe Float)
decodeFloatOrStr =
    JD.oneOf
        [ JD.float |> JD.map Just
        , JD.string |> JD.map String.toFloat
        ]


decodeBoolOrStr : JD.Decoder (Maybe Bool)
decodeBoolOrStr =
    JD.oneOf
        [ JD.bool |> JD.map Just
        , JD.string
            |> JD.andThen
                (\x ->
                    case String.toLower x of
                        "true" ->
                            JD.succeed True

                        "false" ->
                            JD.succeed False

                        _ ->
                            JD.fail ""
                )
            |> JD.map Just
        ]


decodeFlags : JD.Decoder Flags
decodeFlags =
    JD.succeed Flags
        |> required "defaultHomeserverUrl" JD.string
        |> required "serverName" JD.string
        |> required "siteName" JD.string
        |> required "commentSectionId" decodeCommentSectionId
        |> optional "storedSession" (JD.nullable decodeStoredSession) Nothing
        |> optional "pageSize" decodeIntOrStr Nothing
        |> optional "loginEnabled" decodeBoolOrStr Nothing
        |> optional "guestPostingEnabled" decodeBoolOrStr Nothing
        |> optional "updateInterval" decodeFloatOrStr Nothing


decodeCommentSectionId : JD.Decoder String
decodeCommentSectionId =
    JD.string
        |> JD.andThen
            (\csid ->
                if String.contains "_" csid then
                    JD.fail "commentSectionId can't contain underscores"

                else
                    JD.succeed csid
            )
        |> JD.andThen
            (\csid ->
                if String.contains " " csid then
                    JD.fail "commentSectionId can't contain spaces"

                else
                    JD.succeed csid
            )
