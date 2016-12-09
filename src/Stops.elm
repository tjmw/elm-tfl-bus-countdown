module Stops exposing (Msg, update, subscriptions)

import Http
import Json.Encode as Json

import GeoLocationDecoder exposing (decodeGeoLocation)
import Model exposing (Model)
import Ports exposing (geoLocation)
import StopsDocument exposing (StopsDocument)
import StopPointsDecoder exposing (stopPointsDecoder)

type Msg
    = GeoLocation Json.Value
    | FetchStopsError String
    | FetchStopsSuccess StopsDocument


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GeoLocation geoLocationJson ->
            model |> fetchNearbyStops geoLocationJson

        FetchStopsSuccess stopsDocument ->
            model |> updateStops stopsDocument

        FetchStopsError message ->
            model |> handleFetchStopsError message


subscriptions : Sub Msg
subscriptions =
    geoLocation GeoLocation


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
