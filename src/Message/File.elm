module Message.File exposing (FileData, decodeFile, viewFile)

import Accessibility exposing (Html, a, i, p, text)
import ApiUtils exposing (httpFromMxc)
import Html.Attributes exposing (class, href, rel)
import Json.Decode as JD


{-| This module contains functions for decoding and rendering m.file message events.
-}
type alias FileData =
    { body : String
    , url : String
    }


decodeFile : JD.Decoder FileData
decodeFile =
    JD.map2
        FileData
        (JD.field "body" JD.string)
        (JD.field "url" JD.string)


viewFile : String -> FileData -> Html msg
viewFile homeserverUrl file =
    let
        link =
            httpFromMxc homeserverUrl file.url
    in
    case link of
        Just httpLink ->
            --
            a
                [ class "cactus-message-file"
                , rel "noopener"
                , href httpLink
                ]
                [ text <| "📎 Download " ++ file.body ]

        Nothing ->
            p [] [ i [] [ text "Error: Could not parse file URL" ] ]
