module Message.Image exposing (ImageData, decodeImage, viewImage)

import Accessibility exposing (Html, a, i, img, p, text)
import ApiUtils exposing (httpFromMxc)
import Html.Attributes exposing (class, height, href, src, width)
import Json.Decode as JD


type alias ImageData =
    { body : String
    , url : String
    , info : Maybe ImageInfo
    }


type alias ImageInfo_ a =
    { a
        | w : Int
        , h : Int
    }


type alias ThumbnailInfo =
    ImageInfo_ {}


type alias ImageInfo =
    ImageInfo_
        { thumbnail_url : Maybe String
        , thumbnail_info : Maybe ThumbnailInfo
        }


decodeImage : JD.Decoder ImageData
decodeImage =
    JD.map3 ImageData
        (JD.field "body" JD.string)
        (JD.field "url" JD.string)
        (JD.maybe <| JD.field "info" decodeImageInfo)


decodeImageInfo : JD.Decoder ImageInfo
decodeImageInfo =
    JD.map4
        (\w h tnurl tninfo ->
            { w = w
            , h = h
            , thumbnail_url = tnurl
            , thumbnail_info = tninfo
            }
        )
        (JD.field "w" JD.int)
        (JD.field "h" JD.int)
        (JD.maybe <| JD.field "thumbnail_url" JD.string)
        (JD.maybe <| JD.field "thumbnail_info" decodeThumbnailInfo)


decodeThumbnailInfo : JD.Decoder ThumbnailInfo
decodeThumbnailInfo =
    JD.map2
        (\w h -> { w = w, h = h })
        (JD.field "w" JD.int)
        (JD.field "h" JD.int)


viewImage : String -> ImageData -> Html msg
viewImage homeserverUrl image =
    let
        mainImage : ( Maybe String, Maybe ImageInfo )
        mainImage =
            ( httpFromMxc homeserverUrl image.url
            , image.info
            )

        thumbnail : Maybe ( String, ThumbnailInfo )
        thumbnail =
            image.info
                |> Maybe.andThen
                    (\info ->
                        case
                            ( Maybe.map (httpFromMxc homeserverUrl) info.thumbnail_url
                                |> Maybe.withDefault Nothing
                            , info.thumbnail_info
                            )
                        of
                            ( Just url, Just tninfo ) ->
                                Just ( url, tninfo )

                            _ ->
                                Nothing
                    )
    in
    case ( mainImage, thumbnail ) of
        ( ( Just mainUrl, _ ), Just ( tnurl, tninfo ) ) ->
            -- valid image url and thumbnail
            -- render thumbnail
            a [ href mainUrl ]
                [ img image.body
                    [ class "cactus-message-image"
                    , src tnurl
                    , width tninfo.w
                    , height tninfo.h
                    ]
                ]

        ( ( Just mainUrl, Just info ), Nothing ) ->
            -- valid url, no thumbnail, full main image metadata
            -- just show main imagae
            a [ href mainUrl ]
                [ img image.body
                    [ class "cactus-message-image"
                    , src mainUrl
                    , width info.w
                    , height info.h
                    ]
                ]

        ( ( Just mainUrl, Nothing ), Nothing ) ->
            -- valid url, nothing else
            a [ href mainUrl ]
                [ img image.body
                    [ class "cactus-message-image"
                    , src mainUrl
                    ]
                ]

        _ ->
            p [] [ i [] [ text "Error: Could not render image" ] ]
