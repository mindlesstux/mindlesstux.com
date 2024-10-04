module TestConfig exposing (..)

import Config exposing (StaticConfig, decodeFlags, makeRoomAlias, parseFlags)
import Duration
import Expect exposing (Expectation)
import Json.Decode as JD
import Session
import Test exposing (..)


testMakeRoomAlias : Test
testMakeRoomAlias =
    describe "Test makeRoomAlias"
        [ test "makeRoomAlias with realistic values" <|
            \_ ->
                makeRoomAlias { siteName = "myblog", commentSectionId = "october-blogpost", serverName = "matrix.example.com" }
                    |> Expect.equal "#comments_myblog_october-blogpost:matrix.example.com"
        , test "makeRoomAlias with other values..." <|
            \_ ->
                makeRoomAlias { siteName = "a", commentSectionId = "b", serverName = "c" }
                    |> Expect.equal "#comments_a_b:c"
        ]


minimalValidJson : String
minimalValidJson =
    """
      {
        "defaultHomeserverUrl": "https://example.com",
        "serverName": "example.com",
        "siteName": "blog.example.com",
        "commentSectionId": "myCommentSection",
        "storedSession": null
      }
    """


testDecodeMinimalConfig : Test
testDecodeMinimalConfig =
    let
        result : Result JD.Error ( StaticConfig, Maybe Session.Session )
        result =
            minimalValidJson
                |> JD.decodeString decodeFlags
                |> Result.map parseFlags
    in
    test "Decode minimal configuration flags" <|
        \_ ->
            result
                |> Result.map
                    (\( conf, sess ) ->
                        Expect.all
                            [ \( _, s ) -> Expect.equal s Nothing
                            , \( c, _ ) ->
                                Expect.equal c
                                    { defaultHomeserverUrl = "https://example.com"
                                    , roomAlias = "#comments_blog.example.com_myCommentSection:example.com"
                                    , pageSize = 10
                                    , loginEnabled = True
                                    , guestPostingEnabled = True
                                    , updateInterval = Duration.seconds 0
                                    }
                            ]
                            ( conf, sess )
                    )
                |> Result.withDefault (Expect.fail "Configuration did not decode")


completeValidJson : String
completeValidJson =
    """
      {
        "defaultHomeserverUrl": "https://example.com:8448",
        "serverName": "example.com",
        "siteName": "anotherblog.example.com",
        "commentSectionId": "anotherCommentSection",
        "pageSize": 2,
        "loginEnabled": false,
        "guestPostingEnabled": false,
        "updateInterval": 500,
        "storedSession": {
          "homeserverUrl": "https://example.com:8448",
          "kind": "guest",
          "txnId": 0,
          "userId": "@1234:example.com",
          "accessToken": "abcdVerySecret"
        }
      }
    """


completeValidJsonDecoded =
    { defaultHomeserverUrl = "https://example.com:8448"
    , roomAlias = "#comments_anotherblog.example.com_anotherCommentSection:example.com"
    , pageSize = 2
    , loginEnabled = False
    , guestPostingEnabled = False
    , updateInterval = Duration.seconds 500.0
    }


testDecodeCompleteConfig : Test
testDecodeCompleteConfig =
    let
        result : Result JD.Error ( StaticConfig, Maybe Session.Session )
        result =
            completeValidJson
                |> JD.decodeString decodeFlags
                |> Result.map parseFlags
    in
    test "Decode complete configuration JSON" <|
        \_ ->
            result
                |> Result.map
                    (\( conf, sess ) ->
                        Expect.all
                            [ \( _, s ) -> Expect.notEqual s Nothing
                            , \( c, _ ) ->
                                Expect.equal c completeValidJsonDecoded
                            ]
                            ( conf, sess )
                    )
                |> Result.withDefault (Expect.fail "Configuration did not decode")


completeValidStringyJson : String
completeValidStringyJson =
    """
      {
        "defaultHomeserverUrl": "https://example.com:8448",
        "serverName": "example.com",
        "siteName": "anotherblog.example.com",
        "commentSectionId": "anotherCommentSection",
        "pageSize": "2",
        "loginEnabled": "false",
        "guestPostingEnabled": "false",
        "updateInterval": "500",
        "storedSession": {
          "homeserverUrl": "https://example.com:8448",
          "kind": "guest",
          "txnId": 0,
          "userId": "@1234:example.com",
          "accessToken": "abcdVerySecret"
        }
      }
    """


testDecodeCompleteStringyConfig : Test
testDecodeCompleteStringyConfig =
    let
        result : Result JD.Error ( StaticConfig, Maybe Session.Session )
        result =
            completeValidStringyJson
                |> JD.decodeString decodeFlags
                |> Result.map parseFlags
    in
    test "Decode complete configuration JSON with only strings" <|
        \_ ->
            result
                |> Result.map
                    (\( conf, sess ) ->
                        Expect.all
                            [ \( _, s ) -> Expect.notEqual s Nothing
                            , \( c, _ ) ->
                                Expect.equal c completeValidJsonDecoded
                            ]
                            ( conf, sess )
                    )
                |> Result.withDefault (Expect.fail "Configuration did not decode")
