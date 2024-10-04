module Message.Markdown exposing (markdownToHtmlString)

import Html.String as Html exposing (Html)
import Html.String.Attributes as Attr
import Markdown.Block as Block
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer exposing (Renderer)


markdownToHtmlString : String -> Maybe String
markdownToHtmlString mdstr =
    mdstr
        -- parse markdown
        |> (Markdown.Parser.parse >> Result.toMaybe)
        -- render to Html.String
        |> Maybe.map (Markdown.Renderer.render renderer >> Result.toMaybe)
        -- flatten nested maybe
        |> Maybe.withDefault Nothing
        -- List Html.String -> String
        |> Maybe.map (List.map (Html.toString 0) >> String.join "")
        -- if the html is just the input wrapped in p tags,
        -- then the input didn't actually have any html
        |> Maybe.andThen
            (\htmlstr ->
                if htmlstr == "<p>" ++ mdstr ++ "</p>" then
                    Nothing

                else
                    Just htmlstr
            )


{-| This is a modified version of the `defaultHtmlRenderer` from dillonkearns/elm-markdown v6.0.1.
See: <https://github.com/dillonkearns/elm-markdown/blob/6.0.1/src/Markdown/Renderer.elm>

The most important change is that this module imports zwilias/elm-html-string as `Html`,
so this renderer produces a Html.String.Html value, which (unlike Html.Html) can be converted to a string.

This renderer also has a few omissions compared to `Markdown.Html.Renderer.defaultHtmlRenderer`,
so as to prevent it from producing elements that aren't explicitly allowed in the Matrix C/S spec.
See: <https://matrix.org/docs/spec/client_server/r0.6.1#m-room-message-msgtypes>

-}
renderer : Renderer (Html msg)
renderer =
    { heading =
        \{ level, children } ->
            case level of
                Block.H1 ->
                    Html.h1 [] children

                Block.H2 ->
                    Html.h2 [] children

                Block.H3 ->
                    Html.h3 [] children

                Block.H4 ->
                    Html.h4 [] children

                Block.H5 ->
                    Html.h5 [] children

                Block.H6 ->
                    Html.h6 [] children
    , paragraph = Html.p []
    , hardLineBreak = Html.br [] []
    , blockQuote = Html.blockquote []
    , strong = \children -> Html.strong [] children
    , emphasis = \children -> Html.em [] children
    , strikethrough = \children -> Html.del [] children
    , codeSpan = \content -> Html.code [] [ Html.text content ]
    , link =
        \link content ->
            case link.title of
                Just title ->
                    Html.a
                        [ Attr.href link.destination ]
                        content

                Nothing ->
                    Html.a [ Attr.href link.destination ] content
    , image =
        \imageInfo ->
            case imageInfo.title of
                Just title ->
                    Html.img
                        [ Attr.src imageInfo.src
                        , Attr.alt imageInfo.alt
                        , Attr.title title
                        ]
                        []

                Nothing ->
                    Html.img
                        [ Attr.src imageInfo.src
                        , Attr.alt imageInfo.alt
                        ]
                        []
    , text = Html.text
    , unorderedList =
        \items ->
            Html.ul []
                (items
                    |> List.map
                        (\item ->
                            case item of
                                Block.ListItem _ children ->
                                    Html.li [] children
                        )
                )
    , orderedList =
        \startingIndex items ->
            Html.ol
                (case startingIndex of
                    1 ->
                        [ Attr.start startingIndex ]

                    _ ->
                        []
                )
                (items
                    |> List.map
                        (\itemBlocks ->
                            Html.li []
                                itemBlocks
                        )
                )
    , html = Markdown.Html.oneOf []
    , codeBlock =
        \{ body, language } ->
            let
                classes =
                    -- Only the first word is used in the class
                    case Maybe.map String.words language of
                        Just (actualLanguage :: _) ->
                            [ Attr.class <| "language-" ++ actualLanguage ]

                        _ ->
                            []
            in
            Html.pre []
                [ Html.code classes
                    [ Html.text body
                    ]
                ]
    , thematicBreak = Html.hr [] []
    , table = Html.table []
    , tableHeader = Html.thead []
    , tableBody = Html.tbody []
    , tableRow = Html.tr []
    , tableHeaderCell = \_ -> Html.th []
    , tableCell = \_ -> Html.td []
    }
