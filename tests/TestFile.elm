module TestFile exposing (..)

import Expect exposing (Expectation)
import Html exposing (Html)
import Html.Attributes
import Json.Decode as JD
import Message.File exposing (FileData, decodeFile, viewFile)
import Test exposing (..)
import Test.Html.Query
import Test.Html.Selector


decodeAndRender : String -> Result JD.Error (Html msg)
decodeAndRender jsonstr =
    jsonstr
        |> JD.decodeString decodeFile
        |> Result.map (viewFile "https://example.com")


failIfError : Result JD.Error Expectation -> Expectation
failIfError r =
    case r of
        Ok exp ->
            exp

        Err err ->
            Expect.fail <| JD.errorToString err


file_event_content : String
file_event_content =
    -- content field of an m.file event sent from Element
    """
      {
        "body": "plaintext.txt",
        "info": {
          "mimetype": "text/plain",
          "size": 69
        },
        "msgtype": "m.file",
        "url": "mxc://matrix.org/BeqOYyVVkcDyNChnhQMOcInH"
      }
    """


testFileEvent : Test
testFileEvent =
    test "decode and render a file event" <|
        \_ ->
            decodeAndRender file_event_content
                |> Result.map
                    (\r ->
                        Test.Html.Query.fromHtml r
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.tag "a"
                                , Test.Html.Selector.class "cactus-message-file"
                                , Test.Html.Selector.attribute (Html.Attributes.href "https://example.com/_matrix/media/r0/download/matrix.org/BeqOYyVVkcDyNChnhQMOcInH")
                                ]
                    )
                |> failIfError
