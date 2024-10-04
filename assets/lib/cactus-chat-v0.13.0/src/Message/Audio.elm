module Message.Audio exposing (AudioData, decodeAudio, viewAudio)

import Accessibility exposing (Html, audio, i, p, text)
import ApiUtils exposing (httpFromMxc)
import Html.Attributes exposing (class, controls, src)
import Json.Decode as JD


{-| This module contains functions for decoding and rendering m.file message events.
-}
type alias AudioData =
    { body : String
    , url : String
    }


decodeAudio : JD.Decoder AudioData
decodeAudio =
    JD.map2
        AudioData
        (JD.field "body" JD.string)
        (JD.field "url" JD.string)


viewAudio : String -> AudioData -> Html msg
viewAudio homeserverUrl file =
    let
        link =
            httpFromMxc homeserverUrl file.url
    in
    case link of
        Just httpLink ->
            audio
                [ class "cactus-message-audio"
                , src httpLink
                , controls True
                ]
                []

        Nothing ->
            p [] [ i [] [ text "Error: Could not parse audio file URL" ] ]
