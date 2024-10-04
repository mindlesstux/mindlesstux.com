module Editor exposing (Editor(..), Msg, clear, getComment, getName, init, update, view)

import Accessibility exposing (Html, a, button, div, inputText, labelHidden, text, textarea)
import ApiUtils exposing (matrixDotToUrl)
import Html.Attributes exposing (class, disabled, href, placeholder, value)
import Html.Events exposing (onClick, onInput)
import Session exposing (Kind(..), Session, getUserId, isUser)



{- EDITOR
   Handles UI for the comment editor and buttons.
-}


type Editor
    = Editor
        { comment : String
        , name : String
        }


type Msg
    = EditComment String
    | EditName String


clear : Editor -> Editor
clear (Editor editor) =
    Editor { editor | comment = "" }


getComment : Editor -> String
getComment (Editor editor) =
    editor.comment


getName : Editor -> String
getName (Editor editor) =
    if editor.name == "" then
        "Anonymous"

    else
        editor.name


init : Editor
init =
    Editor { comment = "", name = "" }


update : Msg -> Editor -> Editor
update msg (Editor editor) =
    case msg of
        EditComment comment ->
            Editor { editor | comment = comment }

        EditName name ->
            Editor { editor | name = name }


view :
    Editor
    ->
        { session : Maybe Session
        , roomAlias : String
        , loginEnabled : Bool
        , guestPostingEnabled : Bool
        , msgmap : Msg -> msg
        , showLogin : msg
        , logout : msg
        , send : Maybe msg
        }
    -> Html msg
view (Editor editor) { session, roomAlias, loginEnabled, guestPostingEnabled, msgmap, showLogin, logout, send } =
    let
        commentEditor enabled =
            labelHidden
                "Comment Editor"
                []
                (text "Comment Editor")
                (textarea
                    [ class "cactus-editor-textarea"
                    , value editor.comment
                    , onInput <| EditComment >> msgmap
                    , placeholder "Add a comment"
                    , disabled <| not enabled
                    ]
                    []
                )

        sendButton =
            viewSendButton session send editor.comment

        loginButton =
            if loginEnabled then
                loginOrLogoutButton
                    { loginMsg = showLogin
                    , logoutMsg = logout
                    , session = session
                    }

            else
                a
                    [ href <| matrixDotToUrl roomAlias ]
                    [ button [ class "cactus-button" ] [ text "Log in" ] ]

        buttonDiv =
            div [ class "cactus-editor-buttons" ] [ loginButton, sendButton ]

        nameInput =
            if Maybe.map (isUser >> not) session |> Maybe.withDefault True then
                div [ class "cactus-editor-name" ] <|
                    [ labelHidden
                        "Name"
                        []
                        (text "Name")
                        (inputText editor.name
                            [ placeholder "Name"
                            , onInput <| EditName >> msgmap
                            ]
                        )
                    ]

            else
                text ""
    in
    div [ class "cactus-editor" ] <|
        case ( loginEnabled, guestPostingEnabled ) of
            ( True, True ) ->
                -- fully featured
                [ commentEditor True
                , div
                    [ class "cactus-editor-below" ]
                    [ nameInput, buttonDiv ]
                ]

            ( True, False ) ->
                -- disable guest posting, also disables username field
                [ commentEditor <| (Maybe.map isUser session |> Maybe.withDefault False)
                , div
                    [ class "cactus-editor-below" ]
                    [ buttonDiv ]
                ]

            ( False, True ) ->
                -- disable login (replace login button with matrix.to button)
                [ commentEditor True
                , div
                    [ class "cactus-editor-below" ]
                    [ nameInput, buttonDiv ]
                ]

            ( False, False ) ->
                -- no posting. only show matrix.to button
                [ a
                    [ href <| matrixDotToUrl roomAlias
                    , class "cactus-button"
                    , class "cactus-matrixdotto-only"
                    ]
                    [ text "Comment using a Matrix client" ]
                ]


{-| If logged in as a non-guest user, show logout button, else show login
button.
-}
loginOrLogoutButton : { loginMsg : msg, logoutMsg : msg, session : Maybe Session } -> Html msg
loginOrLogoutButton { loginMsg, logoutMsg, session } =
    let
        loginButton =
            button
                [ class "cactus-button"
                , class "cactus-login-button"
                , onClick loginMsg
                ]
                [ text "Log in" ]

        logoutButton =
            button
                [ class "cactus-button"
                , class "cactus-logout-button"
                , onClick logoutMsg
                ]
                [ text "Log out" ]
    in
    case session of
        Just sess ->
            if isUser sess then
                logoutButton

            else
                loginButton

        Nothing ->
            loginButton


viewSendButton : Maybe Session -> Maybe msg -> String -> Html msg
viewSendButton session msg editorContent =
    let
        -- button is disabled if there is no session
        -- or if editor is empty
        isDisabled : Bool
        isDisabled =
            (session == Nothing) || (String.length editorContent == 0)

        attrs =
            [ class "cactus-button"
            , class "cactus-send-button"
            , disabled isDisabled
            ]
                -- append onClick msg if we can
                ++ (msg
                        |> Maybe.map onClick
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []
                   )

        postButtonString =
            case ( Maybe.map isUser session, Maybe.map getUserId session ) of
                ( Just True, Just userid ) ->
                    -- when signed in: show matrix user id on button
                    "Post as " ++ userid

                _ ->
                    -- when unauthenticated or guest
                    "Post"
    in
    button attrs [ text postButtonString ]
