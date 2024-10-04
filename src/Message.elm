module Message exposing
    ( Message(..)
    , decodeMessage
    , formatTimeAsIsoUtcString
    , formatTimeAsUtcString
    , timeSinceText
    , viewMessageEvent
    )

import Accessibility exposing (Html, a, div, img, p, text)
import ApiUtils exposing (thumbnailFromMxc)
import DateFormat
import Duration
import Html.Attributes exposing (class, datetime, href, src, title)
import Json.Decode as JD
import Maybe.Extra
import Member exposing (MemberData)
import Message.Audio exposing (AudioData, decodeAudio, viewAudio)
import Message.File exposing (FileData, decodeFile, viewFile)
import Message.FormattedText exposing (FormattedText(..), decodeFormattedText, viewFormattedText)
import Message.Image exposing (ImageData, decodeImage, viewImage)
import Message.Video exposing (VideoData, decodeVideo, viewVideo)
import Time


type Message
    = Text FormattedText
    | Emote FormattedText
    | Notice FormattedText
    | Image ImageData
    | File FileData
    | Video VideoData
    | Audio AudioData


decodeMessage : JD.Decoder Message
decodeMessage =
    JD.field "msgtype" JD.string
        |> JD.andThen
            (\mt ->
                case mt of
                    "m.text" ->
                        JD.map Text decodeFormattedText

                    "m.emote" ->
                        JD.map Emote decodeFormattedText

                    "m.notice" ->
                        JD.map Notice decodeFormattedText

                    "m.image" ->
                        JD.map Image decodeImage

                    "m.file" ->
                        JD.map File decodeFile

                    "m.audio" ->
                        JD.map Audio decodeAudio

                    "m.video" ->
                        JD.map Video decodeVideo

                    _ ->
                        JD.fail <| "Unsupported msgtype: " ++ mt
            )



-- VIEW


{-| timeSinceText gives a natural language string that says how long ago the
comment was posted.

    timeSince (Time.millisToPosix 4000) (Time.millisToPosix 1000) == "3 seconds ago"

    timeSince (Time.millisToPosix 2000) (Time.millisToPosix 1000) == "1 second ago"

-}
timeSinceText : Time.Posix -> Time.Posix -> String
timeSinceText now then_ =
    let
        age =
            Duration.from then_ now

        allTimeUnits : List ( String, Duration.Duration -> Float )
        allTimeUnits =
            [ ( "year", Duration.inJulianYears )
            , ( "month", Duration.inJulianYears >> (*) 12 )
            , ( "week", Duration.inWeeks )
            , ( "day", Duration.inDays )
            , ( "hour", Duration.inHours )
            , ( "minute", Duration.inMinutes )
            , ( "second", Duration.inSeconds )
            ]

        biggestUnitGreaterThanOne : List ( String, Duration.Duration -> Float ) -> ( String, Duration.Duration -> Float )
        biggestUnitGreaterThanOne timeunits =
            -- expects the unit list to be sorted by size
            case timeunits of
                ( name, unit ) :: rest ->
                    if unit age >= 1 then
                        ( name, unit )

                    else
                        biggestUnitGreaterThanOne rest

                [] ->
                    ( "seconds", Duration.inSeconds )

        ( unitbasename, unitfun ) =
            biggestUnitGreaterThanOne allTimeUnits

        value : Int
        value =
            -- integer value to use
            unitfun age |> floor

        unitname : String
        unitname =
            -- do plural conjugation
            if value == 1 then
                unitbasename

            else
                unitbasename ++ "s"
    in
    if Duration.inSeconds age < 1 then
        "just now"

    else
        String.fromInt value ++ " " ++ unitname ++ " ago"


formatTimeAsUtcString : Time.Posix -> String
formatTimeAsUtcString time =
    let
        -- Format: Sun Mar 14 16:23:15 2021 UTC
        timeFormatter : Time.Zone -> Time.Posix -> String
        timeFormatter =
            DateFormat.format
                [ DateFormat.dayOfWeekNameAbbreviated
                , DateFormat.text " "
                , DateFormat.monthNameAbbreviated
                , DateFormat.text " "
                , DateFormat.dayOfMonthFixed
                , DateFormat.text " "
                , DateFormat.hourMilitaryFixed
                , DateFormat.text ":"
                , DateFormat.minuteFixed
                , DateFormat.text ":"
                , DateFormat.secondFixed
                , DateFormat.text " "
                , DateFormat.yearNumber
                , DateFormat.text " UTC"
                ]
    in
    timeFormatter Time.utc time


formatTimeAsIsoUtcString : Time.Posix -> String
formatTimeAsIsoUtcString time =
    let
        -- Format: 2020-12-03T02:05:16+00:00
        timeFormatter : Time.Zone -> Time.Posix -> String
        timeFormatter =
            DateFormat.format
                [ DateFormat.yearNumber
                , DateFormat.text "-"
                , DateFormat.monthFixed
                , DateFormat.text "-"
                , DateFormat.dayOfMonthFixed
                , DateFormat.text "T"
                , DateFormat.hourMilitaryFixed
                , DateFormat.text ":"
                , DateFormat.minuteFixed
                , DateFormat.text ":"
                , DateFormat.secondFixed
                , DateFormat.text "+00:00"
                ]
    in
    timeFormatter Time.utc time


viewMessageEvent : String -> Time.Posix -> Time.Posix -> String -> Maybe MemberData -> Message -> Html msg
viewMessageEvent defaultHomeserverUrl now messageTime senderId sender message =
    let
        displayname : String
        displayname =
            sender
                |> Maybe.map (\m -> Maybe.withDefault senderId m.displayname)
                |> Maybe.withDefault senderId

        matrixDotToUrl : String
        matrixDotToUrl =
            "https://matrix.to/#/" ++ senderId

        timeStr : String
        timeStr =
            timeSinceText now messageTime

        timeUtc : String
        timeUtc =
            formatTimeAsUtcString messageTime

        timeUtcIso : String
        timeUtcIso =
            formatTimeAsIsoUtcString messageTime

        body : Html msg
        body =
            viewMessage defaultHomeserverUrl displayname message
    in
    div [ class "cactus-comment" ]
        [ -- avatar image
          viewAvatar defaultHomeserverUrl sender
        , div [ class "cactus-comment-content" ]
            -- name and time
            [ div [ class "cactus-comment-header" ]
                [ a
                    [ class "cactus-comment-displayname"
                    , href matrixDotToUrl
                    ]
                    [ text displayname ]
                , Accessibility.time
                    [ class "cactus-comment-time", title timeUtc, datetime timeUtcIso ]
                    [ text timeStr ]
                ]
            , --  body
              div [ class "cactus-comment-body" ] [ body ]
            ]
        ]


viewAvatar : String -> Maybe MemberData -> Html msg
viewAvatar homeserverUrl member =
    let
        avatarUrl : Maybe String
        avatarUrl =
            member
                |> Maybe.andThen .avatarUrl
                |> Maybe.map (thumbnailFromMxc homeserverUrl)
                |> Maybe.Extra.join
    in
    div [ class "cactus-comment-avatar" ] <|
        case avatarUrl of
            Just url ->
                [ img "user avatar image" [ src url ] ]

            Nothing ->
                [ div [ class "cactus-comment-avatar-placeholder" ] [] ]


viewMessage : String -> String -> Message -> Html msg
viewMessage homeserverUrl displayname message =
    case message of
        Text fmt ->
            div
                [ class "cactus-message-text" ]
                (viewFormattedText homeserverUrl fmt)

        Emote (Plain str) ->
            div
                [ class "cactus-message-emote" ]
                [ p [] [ text <| displayname ++ " " ++ str ] ]

        Emote fmt ->
            div
                [ class "cactus-message-text" ]
                (viewFormattedText homeserverUrl fmt)

        Notice fmt ->
            div
                [ class "cactus-message-text" ]
                (viewFormattedText homeserverUrl fmt)

        Image image ->
            viewImage homeserverUrl image

        File file ->
            viewFile homeserverUrl file

        Audio audio ->
            viewAudio homeserverUrl audio

        Video video ->
            viewVideo homeserverUrl video
