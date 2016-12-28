module TichuModelJson exposing (..)

import Array
import Date exposing (Date)
import Json.Decode as Json exposing (..)
import Json.Encode as JE
import String exposing (toInt)
import BaseModel exposing (..)
import UserModel exposing (..)
import TichuModel exposing (..)
import Tuple


gameDecoder : Decoder Game
gameDecoder =
    Json.map6 Game
        (field "name" string)
        (field "users" <| array (map2 (,) userDecoder int))
        (field "round" round)
        (field "history" <| list round)
        (field "messages" <| list message)
        (field "log" <| list gameUpdate)


round : Decoder Round
round =
    Json.map3 Round
        (field "players" <| array player)
        (field "table" <| list (list card))
        (field "actualPlayer" int)


card : Decoder Card
card =
    (field "type" string)
        |> andThen
            (\card ->
                case card of
                    "NormalCard" ->
                        map2
                            (\suit rank -> NormalCard suit rank)
                            suit
                            rank

                    "MahJong" ->
                        succeed MahJong

                    "Dog" ->
                        succeed Dog

                    "Phoenix" ->
                        succeed Phoenix

                    "Dragon" ->
                        succeed Dragon

                    _ ->
                        fail ("Not valid pattern for decoder to Card. Pattern: " ++ toString string)
            )


suit : Decoder Suit
suit =
    (field "suit" string)
        |> andThen
            (\string ->
                case string of
                    "Hearts" ->
                        succeed Hearts

                    "Diamonds" ->
                        succeed Diamonds

                    "Spades" ->
                        succeed Spades

                    "Clubs" ->
                        succeed Clubs

                    _ ->
                        fail ("Not valid pattern for decoder to Suit. Pattern: " ++ toString string)
            )


rank : Decoder Rank
rank =
    (field "rank" string)
        |> andThen
            (\string ->
                case string of
                    "J" ->
                        succeed J

                    "Q" ->
                        succeed Q

                    "K" ->
                        succeed K

                    "A" ->
                        succeed A

                    _ ->
                        case toInt string of
                            Ok i ->
                                succeed (R i)

                            Err err ->
                                fail ("Not valid pattern for decoder to Rank. Pattern: " ++ string)
            )


player : Decoder Player
player =
    map7 Player
        (field "hand" <| list card)
        (field "collected" <| list card)
        (field "selection" <| list card)
        (field "name" string)
        (field "score" int)
        (field "tichu" bool)
        (field "grandTichu" bool)


message : Decoder Message
message =
    map2 Message
        (field "type" messageType)
        (field "text" string)


messageType : Decoder MessageType
messageType =
    string
        |> andThen
            (\string ->
                case string of
                    "Error" ->
                        succeed Error

                    "Warning" ->
                        succeed Warning

                    "Info" ->
                        succeed Info

                    "Success" ->
                        succeed Success

                    _ ->
                        fail ("Not valid pattern for decoder to MessageType. Pattern: " ++ toString string)
            )


gameUpdate : Decoder UpdateGame
gameUpdate =
    fail "Not implemented yet"


gameEncoder : Game -> Value
gameEncoder game =
    JE.object
        [ ( "name", JE.string game.name )
        , ( "users"
          , JE.array
                (Array.map
                    (\( user, int ) ->
                        JE.list [ userEncoder user, JE.int int ]
                    )
                    game.users
                )
          )
        , ( "round", roundEncoder game.round )
        , ( "history", JE.list (List.map roundEncoder game.history) )
        , ( "messages", JE.list (List.map messageEncoder game.messages) )
        , ( "log", JE.list [] )
        ]


messageEncoder : Message -> Value
messageEncoder message =
    JE.object
        []


cardEncoder : Card -> Value
cardEncoder card =
    case card of
        NormalCard suit rank ->
            JE.object
                [ ( "type", JE.string "NormalCard" )
                , ( "suit", JE.string <| toString suit )
                , ( "rank"
                  , JE.string <|
                        case rank of
                            R value ->
                                toString value

                            _ ->
                                toString rank
                  )
                ]

        _ ->
            JE.object
                [ ( "type", JE.string (toString card) ) ]


playerEncoder : Player -> Value
playerEncoder player =
    JE.object
        [ ( "hand", listToValue cardEncoder player.hand )
        , ( "collected", listToValue cardEncoder player.collected )
        , ( "selection", listToValue cardEncoder player.selection )
        , ( "name", JE.string player.name )
        , ( "score", JE.int player.score )
        , ( "tichu", JE.bool player.tichu )
        , ( "grandTichu", JE.bool player.grandTichu )
        ]


roundEncoder : Round -> Value
roundEncoder round =
    JE.object
        [ ( "players", arrayToValue playerEncoder round.players )
        , ( "table", listToValue (List.map cardEncoder >> JE.list) round.table )
        , ( "actualPlayer", JE.int round.actualPlayer )
        ]


encodeGame : Game -> String
encodeGame game =
    JE.encode 0 <| gameEncoder game


encodeSuit : Suit -> Value
encodeSuit item =
    case item of
        Hearts ->
            JE.string "Hearts"

        Diamonds ->
            JE.string "Diamonds"

        Spades ->
            JE.string "Spades"

        Clubs ->
            JE.string "Clubs"


awaitingTableDecoder : Decoder AwaitingTable
awaitingTableDecoder =
    Json.map2 AwaitingTable
        (field "name" string)
        (field "users" <| list (map2 (,) string float))


awaitingTableEncoder : AwaitingTable -> Value
awaitingTableEncoder table =
    JE.object
        [ ( "name", JE.string table.name )
        , ( "users"
          , JE.list
                (List.map (\user -> JE.list [ JE.string <| Tuple.first user, JE.float <| Tuple.second user ])
                    table.users
                )
          )
        ]


encodeAwaitingTable awaitingTable =
    JE.encode 0 <| awaitingTableEncoder awaitingTable