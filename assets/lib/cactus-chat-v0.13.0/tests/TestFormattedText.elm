module TestFormattedText exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer)
import Hex
import Html exposing (div, p)
import Html.Attributes exposing (height, src, width)
import Html.Parser
import Message.FormattedText exposing (FormattedText(..), cleanHtml, viewFormattedText)
import Set exposing (Set)
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (..)
import Time


testViewFormattedText : Test
testViewFormattedText =
    describe "viewFormattedText"
        [ test "Test Plain text" <|
            \_ ->
                (viewFormattedText "https://my.homeserver.tld" <| Plain "just some text")
                    |> div []
                    |> Query.fromHtml
                    |> Query.has [ tag "p", text "just some text" ]
        , test "Plain text with script" <|
            \_ ->
                (viewFormattedText "https://my.homeserver.tld" <| Plain "<script>this will not run</script>")
                    |> div []
                    |> Query.fromHtml
                    |> Query.has [ tag "p", text "<script>this will not run</script>" ]
        , test "Plain text with escaped script" <|
            \_ ->
                (viewFormattedText "https://my.homeserver.tld" <| Plain "<script>this will not run</script>")
                    |> div []
                    |> Query.fromHtml
                    |> Query.hasNot [ tag "script" ]
        , test "Clean image" <|
            let
                cleanImg =
                    Html
                        [ Html.Parser.Element "img"
                            [ ( "width", "200" ), ( "height", "200" ), ( "src", "mxc://olli.ng/sWMkCgSyfhXzCoqWqzImfrFO" ) ]
                            []
                        ]
            in
            \_ ->
                viewFormattedText "https://my.homeserver.tld" cleanImg
                    |> div []
                    |> Query.fromHtml
                    |> Query.has
                        [ tag "img"
                        , attribute <| width 200
                        , attribute <| height 200
                        , attribute <| src "https://my.homeserver.tld/_matrix/media/r0/download/olli.ng/sWMkCgSyfhXzCoqWqzImfrFO"
                        ]
        , test "Dirty image" <|
            let
                dirtyImg =
                    Html
                        [ Html.Parser.Element "img"
                            [ ( "onclick", "alert('haxed')" ), ( "width", "200" ), ( "height", "200" ), ( "src", "https://my.evil.site/exploit.png" ) ]
                            []
                        ]

                fmtHtml =
                    viewFormattedText "https://my.homeserver.tld" dirtyImg
                        |> div []
                        |> Query.fromHtml
            in
            Expect.all
                [ \_ -> Query.hasNot [ attribute <| src "https://my.evil.site/exploit.png" ] fmtHtml
                , \_ -> Query.has [ tag "img", attribute (width 200), attribute (height 200) ] fmtHtml
                ]
        ]



-- IMG COLOR TAGs


badDataMxTest : String -> String -> Test
badDataMxTest attr cssprop =
    fuzz Fuzz.string
        ("Bad " ++ attr)
        (\str ->
            let
                dirtyImg =
                    Html [ Html.Parser.Element "font" [ ( attr, str ) ] [] ]
            in
            viewFormattedText "https://my.homeserver.tld" dirtyImg
                |> div []
                |> Query.fromHtml
                |> Expect.all
                    [ Query.hasNot [ style cssprop str ]
                    , Query.has [ tag "font" ]
                    ]
        )


goodDataMxTest : String -> String -> Test
goodDataMxTest attr cssprop =
    let
        -- make two-char hex byte
        ffFuzzer =
            Fuzz.int
                |> Fuzz.map (modBy 256 >> Hex.toString)
                |> Fuzz.map
                    (\a ->
                        if String.length a == 1 then
                            "0" ++ a

                        else
                            a
                    )

        -- fuzz valid hex colors
        hexColorFuzzer =
            Fuzz.map3
                (\r g b ->
                    r ++ g ++ b
                )
                ffFuzzer
                ffFuzzer
                ffFuzzer
                |> Fuzz.map (\str -> "#" ++ str)
    in
    fuzz hexColorFuzzer
        ("Good " ++ attr)
        (\str ->
            let
                dirtyImg =
                    Html.Parser.Element "font" [ ( attr, str ) ] []

                findStyle node =
                    case node of
                        Html.Parser.Element tag attrs children ->
                            if List.member ( "style", cssprop ++ ":" ++ str ) attrs && tag == "font" then
                                Expect.pass

                            else
                                List.map findStyle children
                                    |> (\exps ->
                                            if List.member Expect.pass exps then
                                                Expect.pass

                                            else
                                                Expect.fail "not found here"
                                       )

                        _ ->
                            Expect.fail "not found here"
            in
            cleanHtml "https://lol.com" dirtyImg
                |> findStyle
        )


badDataMxColorTest =
    badDataMxTest "data-mx-color" "color"


goodDataMxColorTest =
    goodDataMxTest "data-mx-color" "color"


badDataMxBgColorTest =
    badDataMxTest "data-mx-bg-color" "background"


goodDataMxBgColorTest =
    goodDataMxTest "data-mx-bg-color" "background"



-- TEST HTML SANITIZING


tagWhitelist : Set String
tagWhitelist =
    Set.fromList [ "font", "del", "h1", "h2", "h3", "h4", "h5", "h6", "blockquote", "p", "a", "ul", "ol", "sup", "sub", "li", "b", "i", "u", "strong", "em", "strike", "code", "hr", "br", "div", "table", "thead", "tbody", "tr", "th", "td", "caption", "pre", "span", "img" ]


testTagWhitelist : Test
testTagWhitelist =
    describe "Test html sanitization"
        [ fuzz (Fuzz.oneOf [ nestedElementFuzzer 100, wideElementFuzzer ])
            "Check that cleanHtml keeps all tags in whitelist"
            (\input ->
                -- result contains all the valid input tags
                Expect.equal
                    -- valid tags from input + div
                    (allElementTags input |> Set.intersect tagWhitelist |> Set.insert "div")
                    -- all tags from output + div
                    (cleanHtml "https://cactus.chat" input |> allElementTags |> Set.insert "div")
            )
        ]


allElementTags : Html.Parser.Node -> Set String
allElementTags html =
    case html of
        Html.Parser.Element tag _ children ->
            List.foldl
                (\ch set -> Set.union set <| allElementTags ch)
                (Set.singleton tag)
                children

        Html.Parser.Text _ ->
            Set.empty

        Html.Parser.Comment _ ->
            Set.empty



-- FUZZING


nestedElementFuzzer : Int -> Fuzzer Html.Parser.Node
nestedElementFuzzer depth =
    Fuzz.map3 Html.Parser.Element
        (Fuzz.oneOf [ shortStringFuzzer, validTagFuzzer ])
        (Fuzz.list attributeFuzzer)
        (Fuzz.map List.singleton <|
            if depth > 0 then
                nestedElementFuzzer (depth - 1)

            else
                Fuzz.oneOf [ textFuzzer, commentFuzzer ]
        )


wideElementFuzzer : Fuzzer Html.Parser.Node
wideElementFuzzer =
    Fuzz.map (Html.Parser.Element "div" []) <|
        Fuzz.list childlessElementFuzzer


childlessElementFuzzer : Fuzzer Html.Parser.Node
childlessElementFuzzer =
    Fuzz.map2 Html.Parser.Element
        (Fuzz.oneOf [ shortStringFuzzer, validTagFuzzer ])
        (Fuzz.list attributeFuzzer)
        |> Fuzz.map (\a -> a [])


commentFuzzer : Fuzzer Html.Parser.Node
commentFuzzer =
    Fuzz.map Html.Parser.Comment shortStringFuzzer


textFuzzer : Fuzzer Html.Parser.Node
textFuzzer =
    Fuzz.map Html.Parser.Text shortStringFuzzer


attributeFuzzer : Fuzzer ( String, String )
attributeFuzzer =
    Fuzz.oneOf [ invalidAttributeFuzzer, validAttributeFuzzer ]


invalidAttributeFuzzer : Fuzzer ( String, String )
invalidAttributeFuzzer =
    Fuzz.map2 Tuple.pair shortStringFuzzer shortStringFuzzer


validAttributeFuzzer : Fuzzer ( String, String )
validAttributeFuzzer =
    -- these attributes are valid only on specific tags
    let
        attr =
            Fuzz.oneOf <|
                List.map Fuzz.constant
                    [ "href"
                    , "src"
                    , "data-mx-color"
                    , "data-mx-bg-color"
                    , "alt"
                    , "title"
                    ]
    in
    Fuzz.map2 Tuple.pair
        attr
        shortStringFuzzer


validTagFuzzer : Fuzzer String
validTagFuzzer =
    tagWhitelist
        |> Set.toList
        |> List.map Fuzz.constant
        |> Fuzz.oneOf


shortStringFuzzer : Fuzzer String
shortStringFuzzer =
    Fuzz.map3 (\a b c -> String.fromList [ a, b, c ])
        Fuzz.char
        Fuzz.char
        Fuzz.char
