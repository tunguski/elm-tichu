module TableView exposing (..)

import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Navigation 
import Json.Decode as Json exposing (..)
import Result exposing (toMaybe)
import Http
import Task exposing (Task)
import Time exposing (Time, every, second, now)


import Config exposing (..)
import Component exposing (..)
import BaseModel exposing (..)
import TichuModel exposing (..)
import TichuModelJson exposing (..)


component : String -> Component Model msg Msg
component name = 
  Component (model name) update view 
      (Just (init name)) 
      (Just subs) 


onError : (x -> Task y a) -> Task x a -> Task y a
onError fn task =
    Task.onError task fn


ignoreError : Task y a -> Task x a -> Task y a
ignoreError errorTask task =
    Task.onError task (\error -> errorTask)


andThen : (a -> Task x b) -> Task x a -> Task x b
andThen fn task =
    Task.andThen task fn


andThenReturn : Task x b -> Task x a -> Task x b
andThenReturn fn task =
    Task.andThen task (\result -> fn)


-- MODEL


type alias Model =
  { name : String
  , awaitingTable : Maybe AwaitingTable
  , game : Maybe Game
  , lastFinishedTableUpdate : Maybe Time
  }


model : String -> Model
model name =
  Model name Nothing Nothing Nothing


getTable : String -> (Result Http.Error Game -> msg) -> Cmd msg
getTable baseUrl msg =
  Http.get gameDecoder
  (baseUrl ++ "tables")
    |> Task.perform Err Ok
    |> Cmd.map msg


init : String -> Context msg Msg -> Cmd msg
init name ctx =
  Task.map2
    (,)
    now
    (
      (Http.get awaitingTableDecoder
        (baseUrl ++ "awaitingTables/" ++ name)
        |> Task.map Ok
      )
      |> onError (\error ->
        (Http.get gameDecoder
          (baseUrl ++ "game/" ++ name))
          |> Task.map Err
      )
    )
  |> Task.perform Err Ok
  |> Cmd.map UpdateTables
  |> Cmd.map ctx.mapMsg


subs : Context msg Msg -> model -> Sub msg
subs ctx model =
  every second CheckUpdate 
    |> Sub.map ctx.mapMsg


-- UPDATE


type Msg
  = UpdateTables (Result Http.Error (Time, Result Game AwaitingTable))
  | CheckUpdate Time


update : ComponentUpdate Model msg Msg
update ctx action model =
  case action of
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
            } ! [ init model.name ctx ]
          else
            model ! []
        _ ->
          model ! []


-- VIEW


view : ComponentView Model msg Msg
view ctx model =
  Page "Table" <|
    multiCellRow
      [ (2, [ div [ class "table-chat" ]
          [ div [ class "chat-header" ] [ text "Chat" ]
          , div [] [ text "fsdds" ]
          , div [] [ text "asdf" ]
          ] ])
      , (8, [ div [ class "table-main" ] [ text "main" ] ])
      , (2, [ div [ class "table-options" ]
          [div [ class "table-options-header" ] [ text "Game" ]
          ] ])
      ]

