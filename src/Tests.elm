module Tests exposing (..)


import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Navigation 
import Json.Decode as Json exposing (..)
import Result exposing (toMaybe)
import Http
import Random
import Task exposing (Task)
import Time exposing (Time, every, second, now)


import Config exposing (..)
import Component exposing (..)
import BaseModel exposing (..)
import TichuModel exposing (..)
import TichuModelJson exposing (..)
import TableView exposing (..)


component : Component Model msg Msg
component = 
  Component model update view 
      (Just init) 
      (Just subs) 


-- MODEL


type alias Model =
  { seed : Int
  , awaitingTable : Maybe AwaitingTable
  , game : Maybe Game
  , lastFinishedTableUpdate : Maybe Time
  , deserializedGame : Result String Game
  , deserializedAwaitingTable : Result String AwaitingTable
  }


model : Model
model =
  Model 0 Nothing Nothing Nothing
    ( initialGame "TestGame"
      |> encodeGame
      |> decodeString gameDecoder
    )
    ( AwaitingTable "AwaitingTable" [ ("player one", 0) ]
      |> encodeAwaitingTable
      |> decodeString awaitingTableDecoder
    )


init : Context msg Msg -> Cmd msg
init ctx =
  Random.generate BaseRandom (Random.int 0 Random.maxInt)
  |> Cmd.map ctx.mapMsg


subs : Context msg Msg -> model -> Sub msg
subs ctx model =
  every second CheckUpdate 
    |> Sub.map ctx.mapMsg


-- UPDATE


type Msg
  = BaseRandom Int
  | UpdateTables (Result Http.Error (Time, Result Game AwaitingTable))
  | CheckUpdate Time


update : ComponentUpdate Model msg Msg
update ctx action model =
  case action of
    BaseRandom int ->
      { model | seed = int } ! []
    UpdateTables result ->
      case result of
        Ok (time, res) ->
          let
            newModel = { model
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
            } ! [ init ctx ]
          else
            model ! []
        _ ->
          model ! []


-- VIEW


testHeader name passed =
  h4 [] [ text ((if passed then "[SUCC] " else "[FAIL] ") ++ name)]


resultSuccess result =
  case result of
    Ok _ -> True
    Err _ -> False


view : ComponentView Model msg Msg
view ctx model =
  Page ("Tests [seed: " ++ (toString model.seed) ++ "]" ) <|
    fullRow
      [ testHeader "serialize/deserialize Game" (resultSuccess model.deserializedGame) 
      , div [] [ text <| toString model.deserializedGame ]
      , testHeader "serialize/deserialize AwaitingTable" (resultSuccess model.deserializedAwaitingTable) 
      , div [] [ text <| toString model.deserializedAwaitingTable ]
      ]


