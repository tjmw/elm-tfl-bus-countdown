module Main exposing (..)

import Dict exposing (Dict)
import Html exposing (Html, div, span, text, button, input, table, tr, td)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (placeholder, class)
import Http
import Json.Encode as Json
import String
import Task exposing (Task)
import Model exposing (Model, emptyModel)
import Ports exposing (registerForLivePredictions, deregisterFromLivePredictions, predictions, requestGeoLocation, geoLocation)
import Prediction exposing (Prediction, secondsToMinutes)
import PredictionDecoder exposing (decodePredictions, initialPredictionsDecoder)
import PredictionsUpdater exposing (updatePredictions)
import Stops
import Stop exposing (Stop)
import StopsDocument exposing (StopsDocument)
import Date exposing (Date, hour, minute)
import Time exposing (Time, second)


-- MODEL


init : ( Model, Cmd Msg )
init =
    ( emptyModel, Cmd.none )



-- MESSAGES


type Msg
    = NoOp
    | RequestGeoLocation
    | StopsMsg Stops.Msg
    | SelectStop String
    | InitialPredictionsError String
    | InitialPredictionsSuccess (List Prediction)
    | Predictions Json.Value
    | BackToStops
    | PruneExpiredPredictions Time



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick RequestGeoLocation ] [ text "Show nearby stops" ]
        , if model.naptanId /= "" then
            renderPredictions model
          else if model.possibleStops /= [] then
            renderStops model
          else
            text ""
        ]


renderStops : Model -> Html Msg
renderStops model =
    div [] (List.map renderStop model.possibleStops)


renderStop : Stop -> Html Msg
renderStop stop =
    div [ class "stop", onClick (SelectStop stop.naptanId) ]
        [ span [] [ text stop.naptanId ]
        , span [] [ text stop.indicator ]
        , span [] [ text stop.commonName ]
        ]


renderBackToStops : Html Msg
renderBackToStops =
    div [ onClick BackToStops ] [ text "Back to stops" ]


renderPredictions : Model -> Html Msg
renderPredictions model =
    let
        sortedPredictions =
            List.sortBy .timeToStation <| Dict.values model.predictions
    in
        div []
            [ table [] (List.map renderPrediction sortedPredictions)
            , renderBackToStops
            ]


renderPrediction : Prediction -> Html Msg
renderPrediction prediction =
    tr []
        [ td [] [ text prediction.lineName ]
        , td [] [ text prediction.destinationName ]
        , td [] [ text <| formatTime prediction.timeToStation ]
        , td [] [ text prediction.vehicleId ]
        , td [] [ text <| formatDate prediction.timeToLive ]
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
            model |> resetApp

        StopsMsg msg ->
            let
              ( newModel, newStopsCommand ) = model |> Stops.update msg
            in
              ( newModel, Cmd.map StopsMsg newStopsCommand )

        SelectStop newNaptanId ->
            model |> selectStop newNaptanId

        InitialPredictionsSuccess listOfPredictions ->
            model |> handlePredictions listOfPredictions

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
        ( emptyModel, cmd )


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
        stopSubscriptions = Stops.subscriptions
    in
        Sub.batch [ Sub.map StopsMsg stopSubscriptions
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
