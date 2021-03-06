module Tests exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Navigation
import Json.Decode as Json
import Result exposing (toMaybe)
import Random
import Task exposing (..)
import Time exposing (Time, every, second, now)


import ClientApi exposing (..)
import Config exposing (..)
import Component exposing (..)
import BaseModel exposing (..)
import Rest exposing (..)
import SessionModel exposing (..)
import TichuModel exposing (..)
import TichuModelJson exposing (..)
import TableView exposing (..)
import Tests.PlayAGame as PlayAGame
import Tests.Combinations as CardCombinations
import TestBasics exposing (..)


component : Component Model msg Msg
component =
    Component model update view (Just init) Nothing



-- MODEL


type alias Model =
    { seed : Int
    , awaitingTable : Maybe AwaitingTable
    , game : Maybe Game
    , lastFinishedTableUpdate : Maybe Time
    , deserializedGame : Result String Game
    , deserializedAwaitingTable : Result String AwaitingTable
    , playAGame : GameState
    }


model : Model
model =
    Model 0
        Nothing
        Nothing
        Nothing
        (initGame "TestGame" (GameConfig Humans) True 0 []
            |> encodeGame
            |> decodeString gameDecoder
        )
        (AwaitingTable "AwaitingTable" (GameConfig Humans) [ AwaitingTableUser "player one" 0 False True ] True 0
            |> encodeAwaitingTable
            |> decodeString awaitingTableDecoder
        )
        (GameState Nothing [] Nothing)


init : Context msg Msg -> Cmd msg
init ctx =
  Random.generate BaseRandom (Random.int 0 Random.maxInt)
    |> Cmd.map ctx.mapMsg


-- UPDATE


type Msg
    = BaseRandom Int
    | UpdateTables (RestResult ( Time, Result Game AwaitingTable ))
    | CheckUpdate Time
    -- play a game messages
    | PlayAGame PlayAGame.Msg


mapPlayAGame ctx =
    PlayAGame >> ctx.mapMsg


update : ComponentUpdate Model msg Msg
update ctx action model =
    case action of
        PlayAGame m ->
            let
                (playAGame, cmd) =
                    PlayAGame.update
                        model.seed
                        m
                        model.playAGame
            in
                ( { model | playAGame = playAGame }
                , Cmd.map (mapPlayAGame ctx) cmd
                )

        BaseRandom int ->
            let
                newModel = { model | seed = int }
            in
                newModel ! [ PlayAGame.initPlayAGame int newModel |> Cmd.map (mapPlayAGame ctx) ]

        UpdateTables result ->
            case result of
                Ok ( time, res ) ->
                    let
                        newModel =
                            { model
                                | game = Nothing
                                , awaitingTable = Nothing
                                , lastFinishedTableUpdate = Just time
                            }
                    in
                        case res of
                            Ok awaitingTable ->
                                { newModel | awaitingTable = Just awaitingTable } ! []

                            Err game ->
                                { newModel | game = Just game } ! []

                _ ->
                    model ! []

        CheckUpdate time ->
            case model.lastFinishedTableUpdate of
                Just last ->
                    if last + (3 * second) < time then
                        { model
                            | lastFinishedTableUpdate = Nothing
                        }
                            ! [ init ctx ]
                    else
                        model ! []

                _ ->
                    model ! []



-- VIEW


view : ComponentView Model msg Msg
view ctx model =
    Page ("Tests [seed: " ++ (toString model.seed) ++ "]") <|
        fullRow (
            [ testHeader "serialize/deserialize Game" (resultSuccess model.deserializedGame)
            , div [] [ text <| toString model.deserializedGame ]
            , testHeader "serialize/deserialize AwaitingTable" (resultSuccess model.deserializedAwaitingTable)
            , div [] [ text <| toString model.deserializedAwaitingTable ]
            ]
            ++ CardCombinations.testCombinations
            ++ (PlayAGame.view (Context <| mapPlayAGame ctx) model.playAGame)
            )


