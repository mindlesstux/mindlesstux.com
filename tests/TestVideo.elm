module TestVideo exposing (..)

import Expect exposing (Expectation)
import Html exposing (Html)
import Html.Attributes
import Json.Decode as JD
import Message.Video exposing (VideoData, decodeVideo, viewVideo)
import Test exposing (..)
import Test.Html.Query
import Test.Html.Selector


decodeAndRender : String -> Result JD.Error (Html msg)
decodeAndRender jsonstr =
    jsonstr
        |> JD.decodeString decodeVideo
        |> Result.map (viewVideo "https://example.com")


failIfError : Result JD.Error Expectation -> Expectation
failIfError r =
    case r of
        Ok exp ->
            exp

        Err err ->
            Expect.fail <| JD.errorToString err


video_event_content : String
video_event_content =
    -- content field of an m.video event sent from Element
    """
    {
      "body": "video.webm",
      "info": {
        "size": 6826030,
        "mimetype": "video/webm",
        "thumbnail_info": {
          "w": 800,
          "h": 400,
          "mimetype": "image/jpeg",
          "size": 2159
        },
        "w": 1920,
        "h": 960,
        "thumbnail_url": "mxc://olli.ng/TAiHWazIHDRWTBNGqYBITsht"
      },
      "msgtype": "m.video",
      "url": "mxc://olli.ng/jidXyHtxcMglwqJKscmbFeSs"
    }
    """


testVideoEvent : Test
testVideoEvent =
    test "decode and render a video event" <|
        \_ ->
            decodeAndRender video_event_content
                |> Result.map
                    (\r ->
                        Test.Html.Query.fromHtml r
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.tag "video"
                                , Test.Html.Selector.class "cactus-message-video"
                                , Test.Html.Selector.attribute (Html.Attributes.src "https://example.com/_matrix/media/r0/download/olli.ng/jidXyHtxcMglwqJKscmbFeSs")
                                ]
                    )
                |> failIfError
