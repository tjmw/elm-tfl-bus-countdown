module Main exposing (..)

import Dict exposing(Dict)
import Html exposing (Html, div, span, text, button, input, table, tr, td)
import Html.App
import Html.Events exposing (onClick, onInput)
import Json.Encode as Json
import String

import Model exposing (Model, emptyModel)
import Ports exposing (registerForPredictions, predictions)
import Prediction exposing (Prediction, secondsToMinutes)
import PredictionsUpdater exposing (updatePredictions)

-- MODEL

init : ( Model, Cmd Msg )
init =
    ( emptyModel, Cmd.none )

-- MESSAGES

type Msg
    = NoOp
    | UpdateNaptanId String
    | RegisterForPredictions
    | Predictions Json.Value

-- VIEW

view : Model -> Html Msg
view model =
  let
    sortedPredictions = List.sortBy .timeToStation <| Dict.values model.predictions
  in
    div []
        [ input [ onInput UpdateNaptanId ] []
        , button [ onClick RegisterForPredictions ] [ text "Register" ]
        , table [] (List.map drawPrediction sortedPredictions)
        ]

drawPrediction : Prediction -> Html Msg
drawPrediction prediction =
  tr []
      [ td [] [ text prediction.lineName ]
      , td [] [ text prediction.destinationName ]
      , td [] [ text <| formatTime prediction.timeToStation ]
      , td [] [ text prediction.vehicleId ]
      ]

formatTime : Int -> String
formatTime seconds =
  let
    minutes = secondsToMinutes <| seconds
  in
     case minutes of
       0 -> "due"
       1 -> (toString minutes) ++ " min"
       _ -> (toString minutes) ++ " mins"

-- UPDATE

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
          ( model, Cmd.none )
        UpdateNaptanId newNaptanId ->
          ( { model | naptanId = newNaptanId }, Cmd.none )
        RegisterForPredictions ->
          ( model, registerForPredictions model.naptanId )
        Predictions newPredictionsJson ->
          ( updatePredictions model newPredictionsJson, Cmd.none )

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
    predictions Predictions

-- MAIN

main : Program Never
main =
    Html.App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
