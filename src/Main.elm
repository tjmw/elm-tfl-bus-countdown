module Main exposing (..)

import Date exposing (Date, hour, minute)
import Dict exposing (Dict)
import GeoLocationDecoder exposing (decodeGeoLocation)
import Html exposing (Html, div, span, text, button, input, table, tr, td)
import Html.Attributes exposing (placeholder, class, attribute)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Encode as Json
import Model exposing (Model, State(..), emptyModel)
import Ports exposing (registerForLivePredictions, deregisterFromLivePredictions, predictions, requestGeoLocation, geoLocation)
import Prediction exposing (Prediction, secondsToMinutes)
import PredictionDecoder exposing (decodePredictions, initialPredictionsDecoder)
import PredictionsUpdater exposing (updatePredictions)
import Stop exposing (Stop)
import StopsDocument exposing (StopsDocument)
import StopPointsDecoder exposing (stopPointsDecoder)
import String
import Task exposing (Task)
import Time exposing (Time, second)


-- MODEL


init : ( Model, Cmd Msg )
init =
    ( emptyModel, Cmd.none )



-- MESSAGES


type Msg
    = NoOp
    | RequestGeoLocation
    | GeoLocation Json.Value
    | FetchStopsError String
    | FetchStopsSuccess StopsDocument
    | SelectStop String
    | InitialPredictionsError String
    | InitialPredictionsSuccess (List Prediction)
    | Predictions Json.Value
    | BackToStops
    | PruneExpiredPredictions Time



-- VIEW


view : Model -> Html Msg
view model =
    case model.state of
        LoadingStops ->
            renderLoading

        LoadingPredictions ->
            renderLoading

        FetchingGeoLocation ->
            renderLoading

        _ ->
            div []
                [ div [ class "header" ]
                    [ button [ class "pure-button pure-button-primary button-large", onClick RequestGeoLocation ] [ text "Show nearby stops" ]
                    ]
                , div [ class "content" ]
                    [ if model.naptanId /= "" then
                        renderPredictions model
                      else if model.possibleStops /= [] then
                        renderStops model
                      else
                        text ""
                    ]
                ]


renderLoading : Html a
renderLoading =
    div [] [ text "Loading..." ]


renderStops : Model -> Html Msg
renderStops model =
    table [ class "pure-table pure-table-horizontal clickable-table" ] (List.map renderStop model.possibleStops)


renderStop : Stop -> Html Msg
renderStop stop =
    tr [ class "stop", attribute "data-naptan-id" stop.naptanId, onClick (SelectStop stop.naptanId) ]
        [ td [] [ text stop.indicator ]
        , td [] [ text stop.commonName ]
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
            emptyModel |> setState FetchingGeoLocation |> initialSubs

        GeoLocation geoLocationJson ->
            model |> setState LoadingStops |> fetchNearbyStops geoLocationJson

        FetchStopsSuccess stopsDocument ->
            model |> setState ShowingStops |> updateStops stopsDocument

        FetchStopsError message ->
            model |> setState Error |> handleFetchStopsError message

        SelectStop newNaptanId ->
            model |> setState LoadingPredictions |> selectStop newNaptanId

        InitialPredictionsSuccess listOfPredictions ->
            model |> setState ShowingPredictions |> handlePredictions listOfPredictions

        InitialPredictionsError message ->
            model |> setState Error |> handlePredictionsError message

        Predictions newPredictionsJson ->
            model |> handlePredictionsUpdate newPredictionsJson

        BackToStops ->
            model |> setState ShowingStops |> resetSelectedStop

        PruneExpiredPredictions timeNow ->
            model |> handlePruneExpiredPredictions timeNow


setState : State -> Model -> Model
setState newState model =
    { model | state = newState }


fetchNearbyStops : Json.Value -> Model -> ( Model, Cmd Msg )
fetchNearbyStops geoLocationJson model =
    let
        geoLocation =
            decodeGeoLocation geoLocationJson

        url =
            "https://api.tfl.gov.uk/StopPoint?lat=" ++ (toString geoLocation.lat) ++ "&lon=" ++ (toString geoLocation.long) ++ "&stopTypes=NaptanPublicBusCoachTram&radius=200&useStopPointHierarchy=True&returnLines=True&app_id=&app_key=&modes=bus"
    in
        ( model
        , Http.get url stopPointsDecoder
            |> Http.send handleStopsResponse
        )


updateStops : StopsDocument -> Model -> ( Model, Cmd Msg )
updateStops stopsDocument model =
    ( { model | possibleStops = stopsDocument.stopPoints }, Cmd.none )


handleFetchStopsError : String -> Model -> ( Model, Cmd Msg )
handleFetchStopsError message model =
    let
        _ =
            Debug.log "error" message
    in
        ( model, Cmd.none )


handleStopsResponse : Result Http.Error StopsDocument -> Msg
handleStopsResponse result =
    case result of
        Ok stopsDocument ->
            FetchStopsSuccess stopsDocument

        Err msg ->
            FetchStopsError (toString msg)


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


initialSubs : Model -> ( Model, Cmd Msg )
initialSubs model =
    let
        unsubscribeCmd =
            if model.naptanId /= "" then
                deregisterFromLivePredictions model.naptanId
            else
                Cmd.none

        cmd =
            Cmd.batch [ unsubscribeCmd, (requestGeoLocation "") ]
    in
        ( model, cmd )


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
    Sub.batch
        [ geoLocation GeoLocation
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
