module LoginForm exposing (LoginForm, Msg, initLoginForm, showLogin, updateLoginForm, viewLoginForm)

import Accessibility exposing (Html, a, button, div, h3, h4, inputText, label, p, text)
import Accessibility.Widget as Widget
import ApiUtils exposing (UserId, lookupHomeserverUrl, matrixDotToUrl, parseUserId, username)
import Html
import Html.Attributes exposing (attribute, class, disabled, href, placeholder, required, style, type_)
import Html.Events exposing (onClick, onInput)
import Json.Decode as JD
import Maybe.Extra exposing (isJust)
import Session exposing (Session, login)
import Svg exposing (path, svg)
import Svg.Attributes as S exposing (d, viewBox)
import Task exposing (Task)



-- LOGIN FORM


type LoginForm
    = LoginForm
        { userIdField : String
        , userId : Result String UserId
        , passwordField : String
        , homeserverUrlField : Maybe String
        , loginError : Maybe LoginError
        , state : FormState
        }


type FormState
    = Ready
    | LoggingIn
    | Hidden


initLoginForm : LoginForm
initLoginForm =
    LoginForm
        { userIdField = ""
        , userId =
            parseUserId "@alice:example.com"
                |> Result.mapError (\_ -> "Something's wrong with the user ID parser")
        , passwordField = ""
        , homeserverUrlField = Nothing
        , loginError = Nothing
        , state = Hidden
        }


type Msg
    = EditUserId String
    | EditPassword String
    | EditHomeserverUrl String
    | HideLogin
    | Login UserId
    | LoggedIn (Result LoginError Session)


updateLoginForm : LoginForm -> Msg -> ( LoginForm, Cmd Msg, Maybe Session )
updateLoginForm (LoginForm form) msg =
    let
        updateState f =
            ( LoginForm f, Cmd.none, Nothing )
    in
    case msg of
        EditPassword password ->
            updateState { form | passwordField = password }

        EditHomeserverUrl homeserverUrl ->
            updateState { form | homeserverUrlField = Just homeserverUrl }

        EditUserId userIdStr ->
            -- parse userid
            updateState
                { form
                    | userIdField = userIdStr
                    , userId = parseUserId userIdStr
                }

        HideLogin ->
            updateState { form | state = Hidden }

        Login userId ->
            ( LoginForm { form | state = LoggingIn }
            , Task.attempt LoggedIn <| loginWithForm (LoginForm form) userId
            , Nothing
            )

        LoggedIn (Err err) ->
            updateState
                { form
                    | -- login failed. show error
                      loginError = Just err
                    , state = Ready

                    -- enable url field if homeserver err
                    , homeserverUrlField =
                        case ( err, form.homeserverUrlField ) of
                            ( HomeserverLookupFailed _, Nothing ) ->
                                Just ""

                            _ ->
                                form.homeserverUrlField
                }

        LoggedIn (Ok sess) ->
            -- Success! Reset login form and pass session up to caller
            ( initLoginForm
            , Cmd.none
            , Just sess
            )


type LoginError
    = HomeserverLookupFailed String
    | LoginFailed Session.Error


{-| Convert a login error to string for UI stuff
-}
errorToString : LoginError -> String
errorToString err =
    case err of
        HomeserverLookupFailed hserr ->
            "Could not find homeserver: " ++ hserr

        LoginFailed (Session.Error code msg) ->
            code ++ ": " ++ msg


{-| Login with the data from a `LoginForm`.
First look up the homeserver using .well-known, then log in using that homeserver url.
-}
loginWithForm : LoginForm -> UserId -> Task LoginError Session
loginWithForm (LoginForm form) userId =
    case form.homeserverUrlField of
        Just homeserverUrl ->
            login
                { homeserverUrl = homeserverUrl
                , user = username userId
                , password = form.passwordField
                }
                |> Task.mapError LoginFailed

        Nothing ->
            lookupHomeserverUrl userId
                |> Task.mapError HomeserverLookupFailed
                |> Task.andThen
                    (\homeserverUrl ->
                        login
                            { homeserverUrl = homeserverUrl
                            , user = username userId
                            , password = form.passwordField
                            }
                            |> Task.mapError LoginFailed
                    )


{-| Show the login popup.
Sets `LoginForm.state` to `Ready`.
-}
showLogin : LoginForm -> LoginForm
showLogin (LoginForm form) =
    if form.state == Hidden then
        LoginForm { form | state = Ready }

    else
        LoginForm form



-- VIEW


{-| A single text field input, with optional errors and appropriate ARIA tags.
-}
textField :
    { name : String
    , value : String
    , default : String
    , msgf : String -> Msg
    , attrs : List (Html.Attribute Msg)
    , error : Maybe String
    }
    -> Html Msg
textField { name, value, default, msgf, attrs, error } =
    div
        [ class "cactus-login-field" ]
        [ label [ class "cactus-login-label" ] [ text name ]

        -- the text field
        , inputText value
            (attrs
                ++ [ placeholder default
                   , onInput msgf
                   , required True

                   -- accessibility stuff
                   , Widget.label name
                   , Widget.invalid <| isJust error
                   ]
            )

        -- error (or nothing)
        , error
            |> Maybe.map (text >> List.singleton >> p [ class "cactus-login-error" ])
            |> Maybe.withDefault (text "")
        ]


{-| An SVG "X" button that closes the login form
-}
closeButton : Html Msg
closeButton =
    button
        [ class "cactus-login-close"
        , attribute "aria-label" "close"
        , onClick HideLogin
        ]
        [ svg
            [ viewBox "0 0 20 20"
            , S.class "cactus-login-close-icon"
            , style "fill" "currentColor"
            ]
            [ path
                [ style "fill-rule" "evenodd"
                , d "M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                , style "clip-rule" "evenodd"
                ]
                []
            ]
        ]


{-| HTML view for a login form.
-}
viewLoginForm : LoginForm -> String -> Html Msg
viewLoginForm (LoginForm form) roomAlias =
    let
        title =
            h3 [ class "cactus-login-title" ]
                [ text "Log in using Matrix" ]

        clientTitle =
            h4 [ class "cactus-login-client-title" ]
                [ text "Use a Matrix client" ]

        clientLink =
            a
                [ href <| matrixDotToUrl roomAlias
                , class "cactus-button"
                , class "cactus-matrixdotto-button"
                ]
                [ text "Log in" ]

        clientForm =
            div
                [ class "cactus-login-client" ]
                [ clientTitle
                , clientLink
                ]

        credentialsTitle =
            h4 [ class "cactus-login-credentials-title" ]
                [ text "Or type in your credentials" ]

        username =
            textField
                { name = "User ID"
                , default = "@alice:example.com"
                , value = form.userIdField
                , msgf = EditUserId
                , attrs = []
                , error =
                    case form.userId of
                        Err e ->
                            Just e

                        _ ->
                            Nothing
                }

        password =
            textField
                { name = "Password"
                , default = "••••••••••••"
                , value = form.passwordField
                , msgf = EditPassword
                , attrs = [ type_ "password" ]
                , error = Nothing
                }

        homeserverUrl =
            form.homeserverUrlField
                |> Maybe.map
                    (\value ->
                        textField
                            { name = "Homeserver URL"
                            , default = "https://matrix.cactus.chat:8448"
                            , value = value
                            , msgf = EditHomeserverUrl
                            , attrs = []
                            , error = Nothing
                            }
                    )
                |> Maybe.withDefault (text "")

        submitButton =
            button
                ([ class "cactus-button"
                 , class "cactus-login-credentials-button"
                 , disabled <| not (form.state == Ready)
                 ]
                    -- append onclick handler if userid parses
                    ++ (form.userId
                            |> Result.map (Login >> onClick >> List.singleton)
                            |> Result.withDefault []
                       )
                )
                [ text <|
                    case form.state of
                        Ready ->
                            "Log in"

                        LoggingIn ->
                            "Logging in..."

                        Hidden ->
                            ""
                ]

        loginError =
            form.loginError
                |> Maybe.map
                    (errorToString
                        >> text
                        >> List.singleton
                        >> p [ class "cactus-login-error" ]
                    )
                |> Maybe.withDefault (text "")

        credentialsForm =
            div
                [ class "cactus-login-credentials" ]
                [ credentialsTitle
                , username
                , password
                , homeserverUrl
                , submitButton
                , loginError
                ]
    in
    case form.state of
        Hidden ->
            text ""

        _ ->
            Html.div
                [ class "cactus-login-form-wrapper"
                , Html.Events.on "click" <| containerClickDecoder
                ]
                [ div [ class "cactus-login-form" ] <|
                    [ closeButton
                    , title
                    , clientForm
                    , credentialsForm
                    ]
                ]


{-| Decode the json from a click event, and check the class of the targeted
element. Succeed with a Hide Msg if the click was outside the login form.
-}
containerClickDecoder : JD.Decoder Msg
containerClickDecoder =
    JD.at [ "target", "className" ] JD.string
        |> JD.andThen
            (\c ->
                if String.contains "cactus-login-form-wrapper" c then
                    JD.succeed HideLogin

                else
                    JD.fail "Ignoring click event. Didn't hit wrapper."
            )
