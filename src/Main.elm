module Main exposing (..)

import Date exposing (Date, hour, minute)
import Dict exposing (Dict)
import GeoLocationDecoder exposing (decodeGeoLocation)
import Html exposing (Html, div, span, text, button, input, table, tr, td)
import Html.Attributes exposing (placeholder, class, attribute)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Encode as Json
import Line exposing (Line)
import Model exposing (Model, State(..), resetModel)
import NaptanId exposing (NaptanId)
import Ports exposing (registerForLivePredictions, deregisterFromLivePredictions, predictions, requestGeoLocation, geoLocation, geoLocationUnavailable)
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


type alias Flags =
    { tfl_app_id : String
    , tfl_app_key : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( Model Nothing Dict.empty [] Initial flags.tfl_app_id flags.tfl_app_key, Cmd.none )



-- MESSAGES


type Msg
    = NoOp
    | RequestGeoLocation
    | GeoLocation Json.Value
    | GeoLocationUnavailable String
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

        GeoLocationError ->
            renderGeoLocationError |> renderLayout

        ShowingPredictions ->
            renderPredictions model |> renderLayout

        ShowingStops ->
            renderStops model |> renderLayout

        Initial ->
            text "" |> renderLayout

        Error ->
            text "Something went wrong, please try again" |> renderLayout


renderLayout : Html Msg -> Html Msg
renderLayout content =
    div []
        [ div [ class "header" ]
            [ button [ class "pure-button pure-button-primary button-large", onClick RequestGeoLocation ] [ text "Show nearby stops" ]
            ]
        , div [ class "content" ] [ content ]
        ]


renderLoading : Html a
renderLoading =
    div [] [ text "Loading..." ]


renderGeoLocationError : Html a
renderGeoLocationError =
    div [] [ text "Unable to access geolocation. Please allow access and try again." ]


renderStops : Model -> Html Msg
renderStops model =
    if List.isEmpty model.possibleStops then
        div [] [ text "No stops found" ]
    else
        table [ class "pure-table pure-table-horizontal clickable-table" ] (List.map renderStop model.possibleStops)


renderStop : Stop -> Html Msg
renderStop stop =
    tr [ class "stop", attribute "data-naptan-id" stop.naptanId, onClick (SelectStop stop.naptanId) ]
        [ td [ class "stop-indicator" ] [ text stop.indicator ]
        , td [ class "stop-data" ]
            [ text stop.commonName
            , div [ class "stop-direction" ]
                [ span [ class "stop-towards-direction" ] [ text <| formatTowardsDirection stop ]
                , span [ class "stop-compass-direction" ] [ text <| formatCompassDirection stop ]
                ]
            , div [ class "lines" ] (renderLines stop.lines)
            ]
        ]


renderLines : List Line -> List (Html a)
renderLines listOfLines =
    List.map renderLine listOfLines


renderLine : Line -> Html a
renderLine line =
    div [ class "line" ] [ text line.name ]


formatTowardsDirection : Stop -> String
formatTowardsDirection stop =
    case Stop.towardsDirection stop of
        Just dir ->
            "Towards " ++ dir

        Nothing ->
            ""


formatCompassDirection : Stop -> String
formatCompassDirection stop =
    case Stop.compassDirection stop of
        Just dir ->
            "(" ++ dir ++ ")"

        Nothing ->
            ""


renderBackToStops : Html Msg
renderBackToStops =
    div [ class "pure-button", class "back-button", onClick BackToStops ] [ text "Back to stops" ]


renderPredictions : Model -> Html Msg
renderPredictions model =
    let
        sortedPredictions =
            List.sortBy .timeToStation <| Dict.values model.predictions
    in
        if List.isEmpty sortedPredictions then
            div [] [ text "No predicted arrivals" ]
        else
            div []
                [ table [ class "pure-table pure-table-horizontal" ] (List.map renderPrediction sortedPredictions)
                , renderBackToStops
                ]


renderPrediction : Prediction -> Html Msg
renderPrediction prediction =
    tr [ attribute "data-ttl" (toString prediction.timeToLive), attribute "data-vehicle-id" prediction.vehicleId ]
        [ td [ class "prediction-route-number" ] [ text prediction.lineName ]
        , td [ class "prediction-destination" ] [ text prediction.destinationName ]
        , td [ class "prediction-time" ] [ text <| formatTime prediction.timeToStation ]
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
            resetModel model |> setState FetchingGeoLocation |> initialSubs

        GeoLocation geoLocationJson ->
            model |> setState LoadingStops |> fetchNearbyStops geoLocationJson

        GeoLocationUnavailable _ ->
            model |> setState GeoLocationError |> \model_ -> ( model_, Cmd.none )

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

        base_url =
            "https://api.tfl.gov.uk/StopPoint"

        qs =
            "?lat=" ++ (toString geoLocation.lat) ++ "&lon=" ++ (toString geoLocation.long) ++ "&stopTypes=NaptanPublicBusCoachTram&radius=200&useStopPointHierarchy=True&returnLines=True&modes=bus"

        url =
            (base_url ++ qs) |> appendApiCreds model
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
        base_url =
            "https://api.tfl.gov.uk/StopPoint/" ++ newNaptanId ++ "/Arrivals"

        qs =
            "?mode=bus"

        url =
            (base_url ++ qs) |> appendApiCreds model
    in
        ( { model | naptanId = Just (NaptanId.fromString newNaptanId) }
        , Http.get url initialPredictionsDecoder
            |> Http.send handlePredictionsResponse
        )


appendApiCreds : Model -> String -> String
appendApiCreds model url =
    url ++ "&app_id=" ++ model.tfl_app_id ++ "&app_key=" ++ model.tfl_app_key


handlePredictions : List Prediction -> Model -> ( Model, Cmd Msg )
handlePredictions listOfPredictions model =
    ( updatePredictions model listOfPredictions, maybeRegisterCmd model.naptanId )


maybeRegisterCmd : Maybe NaptanId -> Cmd Msg
maybeRegisterCmd naptanId =
    case naptanId of
        Nothing ->
            Cmd.none

        Just id ->
            registerForLivePredictions <| NaptanId.toString id


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
        cmd =
            Cmd.batch [ maybeDeregisterCmd model.naptanId, (requestGeoLocation "") ]
    in
        ( model, cmd )


maybeDeregisterCmd : Maybe NaptanId -> Cmd Msg
maybeDeregisterCmd naptanId =
    case naptanId of
        Nothing ->
            Cmd.none

        Just id ->
            deregisterFromLivePredictions <| NaptanId.toString id


resetSelectedStop : Model -> ( Model, Cmd Msg )
resetSelectedStop model =
    ( { model | predictions = Dict.empty, naptanId = Nothing }, maybeDeregisterCmd model.naptanId )


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
        , geoLocationUnavailable GeoLocationUnavailable
        , predictions Predictions
        , Time.every pruneInterval PruneExpiredPredictions
        ]


pruneInterval : Time
pruneInterval =
    5 * second



-- MAIN


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
