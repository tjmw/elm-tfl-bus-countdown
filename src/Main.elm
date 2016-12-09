module Main exposing (..)

import Dict exposing (Dict)
import Html exposing (Html, div, span, text, button, input, table, tr, td)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (placeholder, class, attribute)
import Http
import Json.Encode as Json
import String
import Task exposing (Task)
import Model exposing (Model, emptyModel)
import Ports exposing (registerForLivePredictions, deregisterFromLivePredictions, predictions, requestGeoLocation, geoLocation)
import Prediction exposing (Prediction, secondsToMinutes)
import PredictionDecoder exposing (decodePredictions, initialPredictionsDecoder)
import PredictionsUpdater exposing (updatePredictions)
import State exposing (Msg(..))
import Stops.State
import Stops.View
import Stop exposing (Stop)
import StopsDocument exposing (StopsDocument)
import Date exposing (Date, hour, minute)
import Time exposing (Time, second)
import Loading exposing (toggleLoading)


-- MODEL


init : ( Model, Cmd Msg )
init =
    ( emptyModel, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    if model.loading then
        div [] [ text "Loading..." ]
    else
        div []
            [ div [ class "header" ]
                [ button [ class "pure-button pure-button-primary button-large", onClick RequestGeoLocation ] [ text "Show nearby stops" ]
                ]
            , div [ class "content" ]
                [ if model.naptanId /= "" then
                    renderPredictions model
                  else if model.possibleStops /= [] then
                    Stops.View.view model |> Html.map StopsMsg
                  else
                    text ""
                ]
            ]


renderBackToStops : Html Msg
renderBackToStops =
    div [ class "pure-button", onClick BackToStops ] [ text "Back to stops" ]


renderPredictions : Model -> Html Msg
renderPredictions model =
    let
        sortedPredictions =
            List.sortBy .timeToStation <| Dict.values model.predictions
    in
        div []
            [ table [ class "pure-table pure-table-horizontal" ] (List.map renderPrediction sortedPredictions)
            , renderBackToStops
            ]


renderPrediction : Prediction -> Html Msg
renderPrediction prediction =
    tr [ attribute "data-ttl" (toString prediction.timeToLive), attribute "data-vehicle-id" prediction.vehicleId ]
        [ td [] [ text prediction.lineName ]
        , td [] [ text prediction.destinationName ]
        , td [] [ text <| formatTime prediction.timeToStation ]
        ]


formatTime : Int -> String
formatTime seconds =
    let
        minutes =
            secondsToMinutes <| seconds
    in
        case minutes of
            0 ->
                "due"

            1 ->
                (toString minutes) ++ " min"

            _ ->
                (toString minutes) ++ " mins"


formatDate : Date.Date -> String
formatDate date =
    (toString (hour date)) ++ ":" ++ (toString (minute date))



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        RequestGeoLocation ->
            model |> toggleLoading |> resetApp

        StopsMsg (Stops.State.SelectStop newNaptanId) ->
            model |> toggleLoading |> selectStop newNaptanId

        StopsMsg msg ->
            let
                ( newModel, newStopsCommand ) =
                    model |> Stops.State.update msg
            in
                ( newModel, Cmd.map StopsMsg newStopsCommand )

        InitialPredictionsSuccess listOfPredictions ->
            model |> toggleLoading |> handlePredictions listOfPredictions

        InitialPredictionsError message ->
            model |> handlePredictionsError message

        Predictions newPredictionsJson ->
            model |> handlePredictionsUpdate newPredictionsJson

        BackToStops ->
            model |> resetSelectedStop

        PruneExpiredPredictions timeNow ->
            model |> handlePruneExpiredPredictions timeNow


selectStop : String -> Model -> ( Model, Cmd Msg )
selectStop newNaptanId model =
    let
        url =
            "https://api.tfl.gov.uk/StopPoint/" ++ newNaptanId ++ "/Arrivals?mode=bus"
    in
        ( { model | naptanId = newNaptanId }
        , Http.get url initialPredictionsDecoder
            |> Http.send handlePredictionsResponse
        )


handlePredictions : List Prediction -> Model -> ( Model, Cmd Msg )
handlePredictions listOfPredictions model =
    ( updatePredictions model listOfPredictions, registerForLivePredictions model.naptanId )


handlePredictionsError : String -> Model -> ( Model, Cmd Msg )
handlePredictionsError message model =
    let
        _ =
            Debug.log "Predictions request failed" message
    in
        ( model, Cmd.none )


handlePredictionsUpdate : Json.Value -> Model -> ( Model, Cmd Msg )
handlePredictionsUpdate newPredictionsJson model =
    ( updatePredictions model <| decodePredictions newPredictionsJson, Cmd.none )


resetApp : Model -> ( Model, Cmd Msg )
resetApp model =
    let
        unsubscribeCmd =
            if model.naptanId /= "" then
                deregisterFromLivePredictions model.naptanId
            else
                Cmd.none

        cmd =
            Cmd.batch [ unsubscribeCmd, (requestGeoLocation "") ]
    in
        ( { model | naptanId = "", predictions = Dict.empty, possibleStops = [] }, cmd )


resetSelectedStop : Model -> ( Model, Cmd Msg )
resetSelectedStop model =
    ( { model | predictions = Dict.empty, naptanId = "" }, deregisterFromLivePredictions model.naptanId )


handlePredictionsResponse : Result Http.Error (List Prediction) -> Msg
handlePredictionsResponse result =
    case result of
        Ok prediction ->
            InitialPredictionsSuccess prediction

        Err msg ->
            InitialPredictionsError (toString msg)


handlePruneExpiredPredictions : Time -> Model -> ( Model, Cmd Msg )
handlePruneExpiredPredictions timeNow model =
    let
        prunedPredictions =
            Dict.filter (\k v -> (Date.toTime v.timeToLive) >= timeNow) model.predictions
    in
        ( { model | predictions = prunedPredictions }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        stopSubscriptions =
            Stops.State.subscriptions
    in
        Sub.batch
            [ Sub.map StopsMsg stopSubscriptions
            , predictions Predictions
            , Time.every pruneInterval PruneExpiredPredictions
            ]


pruneInterval : Time
pruneInterval =
    5 * second



-- MAIN


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
