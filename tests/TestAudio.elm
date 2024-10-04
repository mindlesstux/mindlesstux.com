module TestAudio exposing (..)

import Expect exposing (Expectation)
import Html exposing (Html)
import Html.Attributes
import Json.Decode as JD
import Message.Audio exposing (AudioData, decodeAudio, viewAudio)
import Test exposing (..)
import Test.Html.Query
import Test.Html.Selector


decodeAndRender : String -> Result JD.Error (Html msg)
decodeAndRender jsonstr =
    jsonstr
        |> JD.decodeString decodeAudio
        |> Result.map (viewAudio "https://example.com")


failIfError : Result JD.Error Expectation -> Expectation
failIfError r =
    case r of
        Ok exp ->
            exp

        Err err ->
            Expect.fail <| JD.errorToString err


audio_event_content : String
audio_event_content =
    -- content field of an m.audio event sent from Element
    """
    {
      "body": "hag.mp3",
      "info": {
        "size": 2644885,
        "mimetype": "audio/mpeg"
      },
      "msgtype": "m.audio",
      "url": "mxc://olli.ng/ORlpaptUIgIQNySiRuuEzaXy"
    }
    """


testAudioEvent : Test
testAudioEvent =
    test "decode and render a audio event" <|
        \_ ->
            decodeAndRender audio_event_content
                |> Result.map
                    (\r ->
                        Test.Html.Query.fromHtml r
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.tag "audio"
                                , Test.Html.Selector.class "cactus-message-audio"
                                , Test.Html.Selector.attribute (Html.Attributes.src "https://example.com/_matrix/media/r0/download/olli.ng/ORlpaptUIgIQNySiRuuEzaXy")
                                ]
                    )
                |> failIfError
