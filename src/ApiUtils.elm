module ApiUtils exposing
    ( UserId
    , clientEndpoint
    , httpFromMxc
    , lookupHomeserverUrl
    , matrixDotToUrl
    , mediaEndpoint
    , parseUserId
    , serverNameFromId
    , thumbnailFromMxc
    , toString
    , username
    )

import Http
import Json.Decode as JD
import Parser exposing ((|.), (|=), Parser)
import Set
import Task exposing (Task)
import Url exposing (percentEncode)
import Url.Builder exposing (QueryParameter, crossOrigin)



-- ENDPOINT URLS


apiEndpoint : List String -> String -> List String -> List QueryParameter -> String
apiEndpoint pathPrefix homeserverUrl path params =
    crossOrigin
        homeserverUrl
        (List.map percentEncode <| pathPrefix ++ path)
        params


clientEndpoint : String -> List String -> List QueryParameter -> String
clientEndpoint =
    apiEndpoint [ "_matrix", "client", "r0" ]


mediaEndpoint : String -> List String -> List QueryParameter -> String
mediaEndpoint =
    apiEndpoint [ "_matrix", "media", "r0" ]


{-| Make a matrix.to link from a matrix resource identifier.
This link can be used to access the room from other clients.

    matrixDotToUrl "@asbjorn:olli.ng" == "https://matrix.to/#/%40asbjorn%3Aolli.ng"

    matrixDotToUrl "#roomAlias:matrix.org" == "https://matrix.to/#/%23roomAlias%3Amatrix.org"

-}
matrixDotToUrl : String -> String
matrixDotToUrl identifier =
    -- https://matrix.to/#/<identifier>
    crossOrigin
        "https://matrix.to"
        [ "#", percentEncode identifier ]
        []


{-| Get the server name from a matrix resource identifier by splitting an identifier on ':'

    serverNameFromId "@user:server.com" == Just "server.com"

    serverNameFromId "#room:server.com" == Just "server.com"

    serverNameFromId "foobar" == Nothing

-}
serverNameFromId : String -> Maybe String
serverNameFromId id =
    if String.contains ":" id then
        id
            |> String.split ":"
            |> (List.reverse >> List.head)

    else
        Nothing



-- USERID


{-| User Id parsing implemented based on the identifier grammar described in the spec:
<https://matrix.org/docs/spec/appendices#identifier-grammar>
-}
type UserId
    = UserId String String


toString : UserId -> String
toString (UserId localpart serverpart) =
    "@" ++ localpart ++ ":" ++ serverpart


parseUserId : String -> Result String UserId
parseUserId =
    String.toLower
        >> Parser.run userIdParser
        >> Result.mapError (\_ -> "Must follow format: @user:example.com")


username : UserId -> String
username (UserId name _) =
    name


validLocalpartChar : Char -> Bool
validLocalpartChar c =
    Char.isLower c
        || Char.isDigit c
        || List.member c [ '-', '.', '=', '_', '/' ]


validServernameChar : Char -> Bool
validServernameChar c =
    Char.isAlphaNum c || List.member c [ '.', '-', ':' ]


userIdParser : Parser UserId
userIdParser =
    Parser.succeed UserId
        |. Parser.token "@"
        |= Parser.variable
            { start = validLocalpartChar
            , inner = validLocalpartChar
            , reserved = Set.empty
            }
        |. Parser.token ":"
        |= Parser.variable
            { start = validServernameChar
            , inner = validServernameChar
            , reserved = Set.empty
            }
        |. Parser.end



-- SERVER DISCOVERY


lookupHomeserverUrl : UserId -> Task String String
lookupHomeserverUrl (UserId _ servername) =
    let
        url =
            "https://" ++ servername ++ "/.well-known/matrix/client"
    in
    Http.task
        { method = "GET"
        , url = url
        , headers = []
        , body = Http.emptyBody
        , timeout = Nothing
        , resolver =
            Http.stringResolver <|
                \resp ->
                    case resp of
                        Http.GoodStatus_ _ body ->
                            let
                                dropTrailingSlash : String -> String
                                dropTrailingSlash str =
                                    if String.endsWith "/" str then
                                        String.dropRight 1 str

                                    else
                                        str

                                decoder : JD.Decoder String
                                decoder =
                                    JD.field "m.homeserver" (JD.field "base_url" JD.string)
                                        |> JD.map dropTrailingSlash

                                decoded : Result JD.Error String
                                decoded =
                                    JD.decodeString decoder body
                            in
                            case decoded of
                                Ok result ->
                                    Ok result

                                Err err ->
                                    Err <| JD.errorToString err

                        _ ->
                            Err <| "Failed getting " ++ url
        }



-- MEDIA


{-| Parse a server name from an mxc:// url
Server name grammar found here:
<https://matrix.org/docs/spec/appendices#identifier-grammar>
-}
mxcServerName : String -> Maybe String
mxcServerName mxcUrl =
    let
        validChar : Char -> Bool
        validChar c =
            Char.isAlphaNum c || List.member c [ '.', '-', ':' ]

        parser : Parser String
        parser =
            -- this parser sloppily allows ports in the middle of the domain
            -- like "abcd:8448:wow". it's not ideal but ¯\_(ツ)_/¯
            Parser.succeed identity
                |. Parser.token "mxc://"
                |= Parser.variable
                    { start = validChar
                    , inner = validChar
                    , reserved = Set.empty
                    }
    in
    Parser.run parser mxcUrl
        |> Result.toMaybe


mxcMediaId : String -> Maybe String
mxcMediaId mxcUrl =
    mxcUrl
        |> String.split "/"
        |> (List.reverse >> List.head)


thumbnailFromMxc : String -> String -> Maybe String
thumbnailFromMxc homeserverUrl mxcUrl =
    let
        serverName =
            mxcServerName mxcUrl

        mediaId =
            mxcMediaId mxcUrl
    in
    Maybe.map2
        (\sn mid ->
            mediaEndpoint homeserverUrl
                [ "thumbnail", sn, mid ]
                [ Url.Builder.int "width" 64
                , Url.Builder.int "height" 64
                , Url.Builder.string "method" "crop"
                ]
        )
        serverName
        mediaId


httpFromMxc : String -> String -> Maybe String
httpFromMxc homeserverUrl mxcUrl =
    let
        serverName =
            mxcServerName mxcUrl

        mediaId =
            mxcMediaId mxcUrl
    in
    Maybe.map2
        (\sn mid -> mediaEndpoint homeserverUrl [ "download", sn, mid ] [])
        serverName
        mediaId
