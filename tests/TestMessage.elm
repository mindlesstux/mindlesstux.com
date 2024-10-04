module TestMessage exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Message exposing (..)
import Test exposing (..)
import Time


testTimeSinceText : Test
testTimeSinceText =
    describe "Messages.timeSinceText"
        [ test "three seconds" <|
            \_ ->
                timeSinceText (Time.millisToPosix 4000) (Time.millisToPosix 1000)
                    |> Expect.equal "3 seconds ago"
        , test "five months" <|
            \_ ->
                timeSinceText (Time.millisToPosix 13392000000) (Time.millisToPosix 1000)
                    |> Expect.equal "5 months ago"
        , test "eight years" <|
            \_ ->
                timeSinceText (Time.millisToPosix 257126400000) (Time.millisToPosix 1000)
                    |> Expect.equal "8 years ago"
        , test "just now" <|
            \_ ->
                timeSinceText (Time.millisToPosix 0) (Time.millisToPosix 100)
                    |> Expect.equal "just now"
        , test "one second" <|
            \_ ->
                timeSinceText (Time.millisToPosix 1000) (Time.millisToPosix 0)
                    |> Expect.equal "1 second ago"
        ]


testFormatTimeAsUtcString : Test
testFormatTimeAsUtcString =
    describe "Messages.formatTimeAsUtcString"
        [ test "February 24th, 1978" <|
            \_ ->
                formatTimeAsUtcString (Time.millisToPosix 257149546000) |> Expect.equal "Fri Feb 24 06:25:46 1978 UTC"
        ]


testFormatTimeAsIsoUtcString : Test
testFormatTimeAsIsoUtcString =
    describe "Messages.formatTimeAsIsoUtcString"
        [ test "February 24th, 1978" <|
            \_ ->
                formatTimeAsIsoUtcString (Time.millisToPosix 257149546000) |> Expect.equal "1978-02-24T06:25:46+00:00"
        ]
