module Member exposing (MemberData, decodeMember, setDisplayname)

import Http
import Json.Decode as JD
import Json.Encode as JE
import Session exposing (Session, authenticatedRequest, getUserId)
import Task exposing (Task)


type alias MemberData =
    { membership : Membership
    , displayname : Maybe String
    , avatarUrl : Maybe String
    }


type Membership
    = Invite
    | Join
    | Leave
    | Ban
    | Knock


decodeMember : JD.Decoder MemberData
decodeMember =
    JD.map3
        (\ms dn au ->
            { membership = ms
            , displayname = dn
            , avatarUrl = au
            }
        )
        (JD.field "membership" decodeMembership)
        (JD.maybe <| JD.field "displayname" JD.string)
        (JD.maybe <| JD.field "avatar_url" JD.string)


decodeMembership : JD.Decoder Membership
decodeMembership =
    JD.string
        |> JD.andThen
            (\m ->
                case m of
                    "invite" ->
                        JD.succeed Invite

                    "join" ->
                        JD.succeed Join

                    "leave" ->
                        JD.succeed Leave

                    "ban" ->
                        JD.succeed Ban

                    "knock" ->
                        JD.succeed Knock

                    _ ->
                        JD.fail <| "Invalid membership field: " ++ m
            )


{-| Set display name for a user
-}
setDisplayname : Session -> String -> Task Session.Error ()
setDisplayname session displayname =
    authenticatedRequest session
        { method = "PUT"
        , path = [ "profile", getUserId session, "displayname" ]
        , params = []
        , responseDecoder = JD.succeed ()
        , body = Http.jsonBody <| JE.object [ ( "displayname", JE.string displayname ) ]
        }
