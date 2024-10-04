module TestImage exposing (..)

import Expect exposing (Expectation)
import Html exposing (Html)
import Html.Attributes
import Json.Decode as JD
import Message.Image exposing (ImageData, decodeImage, viewImage)
import Test exposing (..)
import Test.Html.Query
import Test.Html.Selector


decodeAndRender : String -> Result JD.Error (Html msg)
decodeAndRender jsonstr =
    jsonstr
        |> JD.decodeString decodeImage
        |> Result.map (viewImage "https://example.com")


failIfError : Result JD.Error Expectation -> Expectation
failIfError r =
    case r of
        Ok exp ->
            exp

        Err err ->
            Expect.fail <| JD.errorToString err


event_content_image_a =
    """
    {
    "body": "flatmount.png",
    "info": {
      "h": 1800,
      "mimetype": "image/png",
      "size": 135786,
      "thumbnail_info": {
        "h": 500,
        "mimetype": "image/png",
        "size": 36525,
        "w": 800
      },
      "thumbnail_url": "mxc://matrix.org/WkIsslUoLuyGsSHsRRKWUWMe",
      "w": 2880
    },
    "msgtype": "m.image",
    "url": "mxc://matrix.org/PWXbVKjGzmLGgaQvVSAlCfBR"
    }
"""


testDecodeFullImage : Test
testDecodeFullImage =
    test "decode and render a full image event" <|
        \_ ->
            decodeAndRender event_content_image_a
                |> Result.map
                    (\r ->
                        r
                            |> Test.Html.Query.fromHtml
                            |> Expect.all
                                -- check thumbnail image
                                [ \h ->
                                    h
                                        |> Test.Html.Query.find [ Test.Html.Selector.tag "img" ]
                                        |> Test.Html.Query.has
                                            [ Test.Html.Selector.tag "img"
                                            , Test.Html.Selector.class "cactus-message-image"
                                            , Test.Html.Selector.attribute (Html.Attributes.height 500)
                                            , Test.Html.Selector.attribute (Html.Attributes.width 800)
                                            , Test.Html.Selector.attribute (Html.Attributes.src "https://example.com/_matrix/media/r0/download/matrix.org/WkIsslUoLuyGsSHsRRKWUWMe")
                                            ]

                                -- check link to full image
                                , \h ->
                                    h
                                        |> Test.Html.Query.has
                                            [ Test.Html.Selector.tag "a"
                                            , Test.Html.Selector.attribute (Html.Attributes.href "https://example.com/_matrix/media/r0/download/matrix.org/PWXbVKjGzmLGgaQvVSAlCfBR")
                                            ]
                                ]
                    )
                |> failIfError


event_content_image_b =
    """
    {
    "body": "flatmount.png",
    "info": {
      "h": 1800,
      "mimetype": "image/png",
      "size": 135786,
      "w": 2880
    },
    "msgtype": "m.image",
    "url": "mxc://matrix.org/PWXbVKjGzmLGgaQvVSAlCfBR"
    }
"""


testDecodeNoThumbnail : Test
testDecodeNoThumbnail =
    test "decode and render an image event with no thumbnail" <|
        \_ ->
            decodeAndRender event_content_image_b
                |> Result.map
                    (\r ->
                        r
                            |> Test.Html.Query.fromHtml
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.tag "img"
                                , Test.Html.Selector.class "cactus-message-image"
                                , Test.Html.Selector.attribute (Html.Attributes.height 1800)
                                , Test.Html.Selector.attribute (Html.Attributes.width 2880)
                                , Test.Html.Selector.attribute (Html.Attributes.src "https://example.com/_matrix/media/r0/download/matrix.org/PWXbVKjGzmLGgaQvVSAlCfBR")
                                ]
                    )
                |> failIfError


event_content_image_c =
    """
    {
    "body": "flatmount.png",
    "msgtype": "m.image",
    "url": "mxc://matrix.org/PWXbVKjGzmLGgaQvVSAlCfBR"
    }
"""


testMinimalImageEvent : Test
testMinimalImageEvent =
    test "decode and render an image event with only required fields" <|
        \_ ->
            decodeAndRender event_content_image_c
                |> Result.map
                    (\r ->
                        r
                            |> Test.Html.Query.fromHtml
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.tag "img"
                                , Test.Html.Selector.class "cactus-message-image"
                                , Test.Html.Selector.attribute (Html.Attributes.src "https://example.com/_matrix/media/r0/download/matrix.org/PWXbVKjGzmLGgaQvVSAlCfBR")
                                ]
                    )
                |> failIfError


event_content_image_d =
    """
    {
    "body": "flatmount.png",
    "msgtype": "m.image",
    "url": "foobar"
    }
"""


testInvalidImageEvent : Test
testInvalidImageEvent =
    test "decode and render an image event with an invalid mxc url" <|
        \_ ->
            decodeAndRender event_content_image_d
                |> Result.map
                    (\r ->
                        r
                            |> Test.Html.Query.fromHtml
                            |> Test.Html.Query.find [ Test.Html.Selector.tag "i" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Error" ]
                    )
                |> failIfError
