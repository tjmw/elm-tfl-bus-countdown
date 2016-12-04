module Main exposing (..)

import Dict exposing(Dict)
import Html exposing (Html, div, span, text, button, input, table, tr, td)
import Html.App
import Html.Events exposing (onClick, onInput)
import Http
import Json.Encode as Json
import String
import Task exposing (Task)

import Model exposing (Model, emptyModel)
import Ports exposing (registerForLivePredictions, predictions)
import Prediction exposing (Prediction, secondsToMinutes)
import PredictionDecoder exposing (decodePredictions, initialPredictionsDecoder)
import PredictionsFetcher exposing (fetchInitialPredictions)
import PredictionsUpdater exposing (updatePredictions)

-- MODEL

init : ( Model, Cmd Msg )
init =
    ( emptyModel, Cmd.none )

-- MESSAGES

type Msg
    = NoOp
    | UpdateNaptanId String
    | FetchInitialPredictions
    | InitialPredictionsError String
    | InitialPredictionsSuccess (List Prediction)
    | Predictions Json.Value

-- VIEW

view : Model -> Html Msg
view model =
  let
    sortedPredictions = List.sortBy .timeToStation <| Dict.values model.predictions
  in
    div []
        [ input [ onInput UpdateNaptanId ] []
        , button [ onClick FetchInitialPredictions ] [ text "Go" ]
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
    FetchInitialPredictions ->
      let
        url =
          "https://api.tfl.gov.uk/StopPoint/" ++ model.naptanId ++ "/Arrivals?mode=bus"
      in
        ( model,
          Http.get initialPredictionsDecoder url
            |> Task.mapError toString
            |> Task.perform InitialPredictionsError InitialPredictionsSuccess )
    InitialPredictionsSuccess listOfPredictions ->
      ( updatePredictions model listOfPredictions, registerForLivePredictions model.naptanId )
    InitialPredictionsError message ->
      let
        _ = Debug.log "Predictions request failed" message
      in
        (model, Cmd.none)
    Predictions newPredictionsJson ->
      ( updatePredictions model <| decodePredictions newPredictionsJson, Cmd.none )

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
