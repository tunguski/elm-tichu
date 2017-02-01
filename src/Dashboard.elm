module Dashboard exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Navigation
import Json.Decode as Json exposing (..)
import Result exposing (toMaybe)
import Http
import Task
import Dict
import Time exposing (..)


import BaseModel exposing (..)
import ClientApi exposing (..)
import Component exposing (..)
import Config exposing (..)
import Rest exposing (..)
import TichuModel exposing (..)
import TichuModelJson exposing (..)


component : Component Model msg Msg
component =
    Component model update view (Just init) (Just subs)


-- MODEL


type alias Player =
    { name : String
    }


type alias Model =
    { newTableName : String
    , openTables : Maybe (List AwaitingTable)
    , players : Maybe (List Player)
    , lastFinishedTableUpdate : Maybe Time
    , gameConfig : GameConfig
    }


model : Model
model =
    Model "" Nothing Nothing Nothing (GameConfig Humans)


init : Context msg Msg -> Cmd msg
init ctx =
    Task.map2 (,)
      now
      (findAll awaitingTables)
    |> Task.attempt (UpdateTables >> ctx.mapMsg)


subs : Context msg Msg -> model -> Sub msg
subs ctx model =
    every second CheckUpdate
        |> Sub.map ctx.mapMsg



-- UPDATE


type Msg
    = TableName String
    | CreateNewTable
    | OpenTable String
    | UpdateTables (Result Http.Error ( Time, List AwaitingTable ))
    | CheckUpdate Time
    | SwitchTo GameType


update : ComponentUpdate Model msg Msg
update ctx action model =
    case action of
        TableName name ->
            { model | newTableName = name } ! []

        SwitchTo gameType ->
            let
                gameConfig = model.gameConfig
            in
                { model | gameConfig = { gameConfig | gameType = gameType } } ! []

        CreateNewTable ->
            model
                ! [ awaitingTables
                    |> withBody (encodeGameConfig model.gameConfig)
                    |> postCommand model.newTableName
                    |> Task.attempt (\r -> ctx.mapMsg <| OpenTable model.newTableName)
                  ]

        OpenTable name ->
            model
                ! [ Navigation.newUrl ("#/Table/" ++ name) ]

        UpdateTables result ->
            case result of
                Ok ( time, tables ) ->
                    { model
                        | openTables = Just tables
                        , lastFinishedTableUpdate = Just time
                    }
                        ! []

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


gameTypeRadio ctx isChecked description gameType =
    div [ class "form-group" ]
      [ label [ class "radio-inline" ]
          [ input
              ([ type_ "radio"
              , name "game-type"
              , onClick <| ctx.mapMsg <| SwitchTo gameType
              ]
              ++
              case isChecked of
                  True -> [ checked True ]
                  False -> []
              )
              []
          , text description
          ]
      ]


view : ComponentView Model msg Msg
view ctx model =
    Page "Dashboard" <|
        fullRow
            [ Html.form [ class "form-inline" ]
                [ div [ class "form-group" ]
                    [ label [] [ text "Table Name" ]
                    , input
                        [ class "form-control"
                        , placeholder "Unique name"
                        , onInput <| TableName >> ctx.mapMsg
                        ]
                        []
                    ]
                , gameTypeRadio ctx (model.gameConfig.gameType == Humans) "Humans only" Humans
                , gameTypeRadio ctx False "Humans vs. bots" HumansVsBots
                , gameTypeRadio ctx False "Play with bots" Bots
                , button
                    [ class "btn btn-primary"
                    , onClick <| ctx.mapMsg CreateNewTable
                    , type_ "button"
                    ]
                    [ text "Create New Table" ]
                ]
            , h3 [] [ text "Open Tables" ]
            , table [ class "table table-striped x" ]
                [ thead []
                    [ tr []
                        [ th [] [ text "Name" ]
                        , th [] []
                        , th [] [ text "Player" ]
                        ]
                    ]
                , tbody []
                    (case model.openTables of
                        Just tables ->
                            tables|> List.map (\table ->
                                tr []
                                    [ td [] [ a [ href ("#/Table/" ++ table.name) ] [ text table.name ] ]
                                    , td [] [ text (toString (List.length table.users) ++ "/4") ]
                                    , td []
                                        (List.map (.name >> text) table.users)
                                    ]
                            )

                        Nothing ->
                            []
                    )
                ]
            , h3 [] [ text "Players" ]
            , table [ class "table table-striped x" ]
                [ thead []
                    [ tr []
                        [ th [] [ text "Name" ]
                        , th [] [ text "Ranking" ]
                        , th [] [ text "Stats" ]
                        ]
                    ]
                , tbody []
                    [ tr []
                        [ td [] [ text "Name" ]
                        , td [] [ text "Player" ]
                        , td [] [ text "Stats" ]
                        ]
                    , tr []
                        [ td [] [ text "Name" ]
                        , td [] [ text "Player" ]
                        , td [] [ text "Stats" ]
                        ]
                    ]
                ]
            ]
