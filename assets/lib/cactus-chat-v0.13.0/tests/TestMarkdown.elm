module TestMarkdown exposing (..)

import Expect exposing (Expectation)
import Html exposing (Html)
import Html.Attributes
import Message.Image exposing (ImageData, decodeImage, viewImage)
import Message.Markdown exposing (markdownToHtmlString)
import Test exposing (..)
import Test.Html.Query
import Test.Html.Selector


testBoldAndItalic : Test
testBoldAndItalic =
    test "Parse markdown bold and italics" <|
        \_ ->
            markdownToHtmlString "**bold** and *italics*"
                |> Expect.equal (Just "<p><strong>bold</strong> and <em>italics</em></p>")


testList : Test
testList =
    test "Parse markdown list" <|
        \_ ->
            markdownToHtmlString """
- item
- another item
- third item"""
                |> Expect.equal (Just "<ul><li>item</li><li>another item</li><li>third item</li></ul>")


testLink : Test
testLink =
    test "Parse markdown link" <|
        \_ ->
            markdownToHtmlString "[check out this cool commenting system!](https://cactus.chat)"
                |> Expect.equal (Just "<p><a href=\"https://cactus.chat\">check out this cool commenting system!</a></p>")
