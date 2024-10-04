module Message.FormattedText exposing (FormattedText(..), cleanHtml, decodeFormattedText, viewFormattedText)

import Accessibility exposing (Html, div, p, text)
import ApiUtils exposing (httpFromMxc)
import Html.Parser
import Html.Parser.Util
import Json.Decode as JD
import Parser exposing ((|.), Parser)
import Set exposing (Set)
import Tuple



{-
   This module supports message event bodies that optionally have the `formatted_body` and `format` fields.
   Currently the only supported format is `org.matrix.custom.html` (as per the Matrix spec).
   The main responsibility of this module is to parse HTML to avoid XSS.
-}


type FormattedText
    = Plain String
    | Html (List Html.Parser.Node)



-- DECODERS


decodeFormattedText : JD.Decoder FormattedText
decodeFormattedText =
    (JD.maybe <| JD.field "format" JD.string)
        |> JD.andThen
            (\f ->
                case f of
                    Just "org.matrix.custom.html" ->
                        decodeTextHtml

                    _ ->
                        decodeTextPlain
            )


decodeTextPlain : JD.Decoder FormattedText
decodeTextPlain =
    JD.field "body" JD.string
        |> JD.map Plain


decodeTextHtml : JD.Decoder FormattedText
decodeTextHtml =
    JD.field "formatted_body" JD.string
        |> JD.map Html.Parser.run
        |> JD.andThen
            (\html ->
                case html of
                    Err _ ->
                        -- fall back to plain body
                        decodeTextPlain

                    Ok nodes ->
                        -- successful html parse
                        -- XXX: the html is not sanitized at this point
                        --      sanitizaiton happens when viewing
                        JD.succeed (Html nodes)
            )



{- SANITIZE
   Clean parsed HTML, keeping only whitelisted nodes and attributes as per
   the Client-Server API spec r.0.6.1 - 13.2.1.7 m.room.message msgtypes.
   https://matrix.org/docs/spec/client_server/r0.6.1#m-room-message-msgtypes
-}


tagWhitelist : Set String
tagWhitelist =
    Set.fromList
        [ "font"
        , "del"
        , "h1"
        , "h2"
        , "h3"
        , "h4"
        , "h5"
        , "h6"
        , "blockquote"
        , "p"
        , "a"
        , "ul"
        , "ol"
        , "sup"
        , "sub"
        , "li"
        , "b"
        , "i"
        , "u"
        , "strong"
        , "em"
        , "strike"
        , "code"
        , "hr"
        , "br"
        , "div"
        , "table"
        , "thead"
        , "tbody"
        , "tr"
        , "th"
        , "td"
        , "caption"
        , "pre"
        , "span"
        , "img"
        ]


{-| Clean and transform parsed HTML.

Removes tags and attributes not in whitelist.
Transforms mxc urls to http urls, and color tags to css attributes.

-}
cleanHtml : String -> Html.Parser.Node -> Html.Parser.Node
cleanHtml homeserverUrl node_ =
    let
        cleanHtmlNode depth node =
            if depth > 100 then
                Html.Parser.Text ""

            else
                case node of
                    Html.Parser.Text str ->
                        -- raw text gets to stay
                        Html.Parser.Text str

                    Html.Parser.Comment str ->
                        -- keep comments also
                        Html.Parser.Comment str

                    Html.Parser.Element tag attrs children ->
                        (if Set.member tag tagWhitelist then
                            -- tag in whitelist - process
                            Html.Parser.Element tag (cleanAttributes homeserverUrl tag attrs)

                         else
                            -- element not in whitelist.
                            -- remove attributes and replace with div
                            Html.Parser.Element "div" []
                        )
                        <|
                            -- keep child elements in both cases
                            List.map (cleanHtmlNode <| depth + 1) children
    in
    cleanHtmlNode 0 node_


cleanAttributes : String -> String -> List ( String, String ) -> List ( String, String )
cleanAttributes homeserverUrl tag attrs =
    -- keep omly the attributes whitelisted by the client/server api spec
    -- and transform them as per the spec
    case tag of
        "font" ->
            colorAttributes attrs

        "span" ->
            colorAttributes attrs

        "a" ->
            -- "prevent target page from referencing the client's tab/window"
            ( "rel", "noopener" ) :: anchorAttributes attrs

        "img" ->
            imgAttributes homeserverUrl attrs

        "ol" ->
            -- only keep "start"
            List.filter (Tuple.first >> (==) "start") attrs

        "code" ->
            List.filter
                (\( attr, val ) ->
                    (attr == "class")
                        && (String.left 9 val == "language-")
                )
                attrs

        _ ->
            []


{-| Parse String as 7-character hex color code.

e.g. "#ff0000"

-}
parseHexColor : Parser String
parseHexColor =
    Parser.symbol "#"
        |. Parser.chompWhile Char.isHexDigit
        |. Parser.end
        |> Parser.getChompedString
        |> Parser.andThen
            (\hexcolor ->
                if String.length hexcolor == 7 then
                    Parser.succeed hexcolor

                else
                    Parser.problem "Hex color code should have 7 characters."
            )


{-| Keep only the color attributes allowed by the client/server api spec
and translate the color attributes to inline css

    colorAttributes [("data-mx-color", "#ffc0de"), ("foo", "bar"), ("data-mx-bg-color", "#c0deff")]
    == [("style", "color: #ffc0de), ("style", "background: #c0deff")]

-}
colorAttributes : List ( String, String ) -> List ( String, String )
colorAttributes attrs =
    List.foldl
        (\attr list ->
            case attr of
                ( "data-mx-color", value ) ->
                    case Parser.run parseHexColor value of
                        Ok hexColor ->
                            ( "style", "color:" ++ hexColor ) :: list

                        Err _ ->
                            list

                ( "data-mx-bg-color", value ) ->
                    case Parser.run parseHexColor value of
                        Ok hexColor ->
                            ( "style", "background:" ++ hexColor ) :: list

                        Err _ ->
                            list

                _ ->
                    -- discard all other attributes
                    list
        )
        []
        attrs


anchorAttributes : List ( String, String ) -> List ( String, String )
anchorAttributes attrs =
    List.foldl
        (\attr list ->
            case attr of
                ( "name", nameStr ) ->
                    ( "name", nameStr ) :: list

                ( "target", targetStr ) ->
                    ( "target", targetStr ) :: list

                ( "href", hrefStr ) ->
                    let
                        validSchemas =
                            [ "https"
                            , "http"
                            , "ftp"
                            , "mailto"
                            , "magnet"
                            ]

                        hrefClean : Bool
                        hrefClean =
                            List.head (String.split ":" hrefStr)
                                |> Maybe.map (\schema -> List.member schema validSchemas)
                                |> Maybe.withDefault False
                    in
                    if hrefClean then
                        ( "href", hrefStr ) :: list

                    else
                        list

                _ ->
                    list
        )
        []
        attrs


imgAttributes : String -> List ( String, String ) -> List ( String, String )
imgAttributes homeserverUrl attrs =
    List.foldl
        (\attr list ->
            case attr of
                ( "width", _ ) ->
                    attr :: list

                ( "height", _ ) ->
                    attr :: list

                ( "alt", _ ) ->
                    attr :: list

                ( "title", _ ) ->
                    attr :: list

                ( "src", srcStr ) ->
                    -- only keep if mxc parsing succeeds
                    httpFromMxc homeserverUrl srcStr
                        |> Maybe.map (\url -> ( "src", url ) :: list)
                        |> Maybe.withDefault list

                _ ->
                    list
        )
        []
        attrs



-- VIEW


viewFormattedText : String -> FormattedText -> List (Html msg)
viewFormattedText homeserverUrl fmt =
    case fmt of
        Plain str ->
            [ p [] [ text str ] ]

        Html nodes ->
            List.map (cleanHtml homeserverUrl) nodes |> Html.Parser.Util.toVirtualDom
