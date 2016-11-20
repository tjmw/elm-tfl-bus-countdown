port module Main exposing (..)

import Html exposing (Html, div, text)
import Html.App
import String

-- MODEL

type alias Model =
    List String

init : ( Model, Cmd Msg )
init =
    ( [], Cmd.none )

-- MESSAGES

type Msg
    = NoOp
    | Predictions (List String)

-- VIEW

view : Model -> Html Msg
view model =
    div []
        [ text (String.join ", " model) ]

-- UPDATE

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )
        Predictions newPredictions ->
            ( newPredictions, Cmd.none )

-- SUBSCRIPTIONS

port predictions : (List String -> msg) -> Sub msg

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
