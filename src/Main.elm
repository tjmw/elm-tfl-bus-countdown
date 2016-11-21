module Main exposing (..)

import Html exposing (Html, div, span, text, button, input)
import Html.App
import Html.Events exposing (onClick, onInput)
import Json.Encode as Json
import String

import Model exposing (Model, emptyModel)
import Ports exposing (registerForPredictions, predictions)
import Prediction exposing (Prediction)
import PredictionDecoder exposing (decodePredictions)

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
    div []
        [ input [ onInput UpdateNaptanId ] []
        , button [ onClick RegisterForPredictions ] [ text "Register" ]
        , div [] (List.map drawPrediction model.predictions)
        ]

drawPrediction : Prediction -> Html Msg
drawPrediction prediction =
  div []
      [ span [] [ text prediction.lineName ]
      , span [] [ text prediction.destinationName ]
      , span [] [ text <| toString prediction.timeToStation ]
      , span [] [ text prediction.vehicleId ]
      ]

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
          ( { model | predictions = (decodePredictions newPredictionsJson) }, Cmd.none )

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
