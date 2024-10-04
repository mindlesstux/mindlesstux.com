module Message.Video exposing (VideoData, decodeVideo, viewVideo)

import Accessibility exposing (Html, i, p, text, video)
import ApiUtils exposing (httpFromMxc)
import Html.Attributes exposing (alt, class, controls, src)
import Json.Decode as JD


{-| Module for decoding video events and rendering them as HTML.

Data structures are on spec r0.6.1
<https://matrix.org/docs/spec/client_server/r0.6.1#m-video>

-}
type alias VideoData =
    { body : String
    , url : String
    }


decodeVideo : JD.Decoder VideoData
decodeVideo =
    JD.map2 VideoData
        (JD.field "body" JD.string)
        (JD.field "url" JD.string)


viewVideo : String -> VideoData -> Html msg
viewVideo homeserverUrl vdata =
    let
        url : Maybe String
        url =
            httpFromMxc homeserverUrl vdata.url
    in
    case url of
        Just u ->
            video
                [ alt vdata.body
                , src u
                , controls True
                , class "cactus-message-video"
                ]
                []

        Nothing ->
            p [] [ i [] [ text <| "Error: The URL for video \"" ++ vdata.body ++ "\" could not be decoded." ] ]
