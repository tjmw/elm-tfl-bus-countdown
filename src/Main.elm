module Main exposing (..)

import Html exposing (Html, div, text, button, input)
import Html.App
import Html.Events exposing (onClick, onInput)
import String

import Model exposing (Model, emptyModel)
import Ports exposing(registerForPredictions, predictions)

-- MODEL

init : ( Model, Cmd Msg )
init =
    ( emptyModel, Cmd.none )

-- MESSAGES

type Msg
    = NoOp
    | UpdateNaptanId String
    | RegisterForPredictions
    | Predictions (List String)

-- VIEW

view : Model -> Html Msg
view model =
    div []
        [ input [ onInput UpdateNaptanId ] []
        , button [ onClick RegisterForPredictions ] [ text "Register" ]
        , div [] (List.map drawPrediction model.predictions)
        ]

drawPrediction : String -> Html Msg
drawPrediction prediction =
  div []
      [ text prediction ]

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
        Predictions newPredictions ->
          ( { model | predictions = newPredictions }, Cmd.none )

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
