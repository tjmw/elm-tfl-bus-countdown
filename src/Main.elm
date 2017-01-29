module Main exposing (..)

import Date exposing (Date, hour, minute)
import Dict exposing (Dict)
import GeoLocationDecoder exposing (decodeGeoLocation)
import Html exposing (Html, div, span, text, button, input, table, tr, td, a)
import Html.Attributes exposing (placeholder, class, attribute, href)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Encode as Json
import Line exposing (Line)
import Model exposing (Model, State(..), resetModel)
import NaptanId exposing (NaptanId)
import Navigation
import Ports exposing (registerForLivePredictions, deregisterFromLivePredictions, predictions, requestGeoLocation, geoLocation, geoLocationUnavailable)
import Prediction exposing (Prediction, secondsToMinutes)
import PredictionDecoder exposing (decodePredictions, initialPredictionsDecoder)
import PredictionsUpdater exposing (updatePredictions)
import Routing exposing (RoutePath)
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


init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init flags location =
    update (UrlChange location) (Model Nothing Dict.empty [] Initial flags.tfl_app_id flags.tfl_app_key location)



-- MESSAGES


type Msg
    = NoOp
    | Reset
    | RequestGeoLocation
    | GeoLocation Json.Value
    | GeoLocationUnavailable String
    | FetchStopsError String
    | FetchStopsSuccess StopsDocument
    | SelectStop String
    | InitialPredictionsError String
    | InitialPredictionsSuccess (List Prediction)
    | NavigateTo String
    | Predictions Json.Value
    | PruneExpiredPredictions Time
    | UrlChange Navigation.Location



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
            [ a [ class "pure-button pure-button-primary button-large", href "#/locations/find" ] [ text "Show nearby stops" ]
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
    tr [ class "stop", attribute "data-naptan-id" stop.naptanId, onClick <| NavigateTo ("#/stops/" ++ stop.naptanId) ]
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
            model ! []

        Reset ->
            (model |> resetModel) ! []

        RequestGeoLocation ->
            model |> resetModel |> setState FetchingGeoLocation |> initialSubs

        GeoLocation geoLocationJson ->
            model ! [ navigateToLocationPath geoLocationJson ]

        GeoLocationUnavailable _ ->
            model |> setState GeoLocationError |> \model_ -> ( model_, Cmd.none )

        FetchStopsSuccess stopsDocument ->
            model |> setState ShowingStops |> updateStops stopsDocument |> resetSelectedStop

        FetchStopsError message ->
            model |> setState Error |> handleFetchStopsError message |> resetSelectedStop

        SelectStop newNaptanId ->
            model |> setState LoadingPredictions |> selectStop newNaptanId

        InitialPredictionsSuccess listOfPredictions ->
            model |> setState ShowingPredictions |> handlePredictions listOfPredictions

        InitialPredictionsError message ->
            model |> setState Error |> handlePredictionsError message

        Predictions newPredictionsJson ->
            model |> handlePredictionsUpdate newPredictionsJson

        PruneExpiredPredictions timeNow ->
            model |> handlePruneExpiredPredictions timeNow

        UrlChange location ->
            model |> handleRouteChange location

        NavigateTo path ->
            model ! [ Navigation.newUrl path ]


setState : State -> Model -> Model
setState newState model =
    { model | state = newState }


handleRouteChange : Navigation.Location -> Model -> ( Model, Cmd Msg )
handleRouteChange location model =
    let
        newModel =
            { model | currentRoute = location }

        route =
            Routing.fromLocation location
    in
        case route of
            [ "stops", naptanId ] ->
                update (SelectStop naptanId) newModel

            [ "locations", "find" ] ->
                update RequestGeoLocation newModel

            [ "locations", lat, long ] ->
                maybeFetchNearbyStops lat long newModel

            _ ->
                update Reset newModel


navigateToLocationPath : Json.Value -> Cmd Msg
navigateToLocationPath geoLocationJson =
    let
        geoLocation =
            decodeGeoLocation geoLocationJson
    in
        Navigation.newUrl ("#/locations/" ++ (toString geoLocation.lat) ++ "/" ++ (toString geoLocation.long))


maybeFetchNearbyStops : String -> String -> Model -> ( Model, Cmd Msg )
maybeFetchNearbyStops lat long model =
    case model.possibleStops of
        [] ->
            (model |> setState LoadingStops) ! [ fetchNearbyStops lat long model ]

        _ ->
            model |> setState ShowingStops |> resetSelectedStop


fetchNearbyStops : String -> String -> Model -> Cmd Msg
fetchNearbyStops lat long model =
    let
        base_url =
            "https://api.tfl.gov.uk/StopPoint"

        qs =
            "?lat=" ++ (lat) ++ "&lon=" ++ (long) ++ "&stopTypes=NaptanPublicBusCoachTram&radius=200&useStopPointHierarchy=True&returnLines=True&modes=bus"

        url =
            (base_url ++ qs) |> appendApiCreds model
    in
        Http.get url stopPointsDecoder
            |> Http.send handleStopsResponse


updateStops : StopsDocument -> Model -> Model
updateStops stopsDocument model =
    { model | possibleStops = stopsDocument.stopPoints }


handleFetchStopsError : String -> Model -> Model
handleFetchStopsError message model =
    let
        _ =
            Debug.log "error" message
    in
        model


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
    Navigation.programWithFlags UrlChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
