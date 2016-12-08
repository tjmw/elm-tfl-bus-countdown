module Main exposing (..)

import Dict exposing(Dict)
import Html exposing (Html, div, span, text, button, input, table, tr, td)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (placeholder)
import Http
import Json.Encode as Json
import String
import Task exposing (Task)

import Model exposing (Model, emptyModel)
import Ports exposing (registerForLivePredictions, predictions, requestGeoLocation, geoLocation)
import GeoLocationDecoder exposing (decodeGeoLocation)
import Prediction exposing (Prediction, secondsToMinutes)
import PredictionDecoder exposing (decodePredictions, initialPredictionsDecoder)
import PredictionsUpdater exposing (updatePredictions)
import Stop exposing (Stop)
import StopsDocument exposing (StopsDocument)
import StopPointsDecoder exposing (stopPointsDecoder)

-- MODEL

init : ( Model, Cmd Msg )
init =
    ( emptyModel, Cmd.none )

-- MESSAGES

type Msg
    = NoOp
    | UpdateNaptanId String
    | FetchInitialPredictions
    | RequestGeoLocation
    | InitialPredictionsError String
    | InitialPredictionsSuccess (List Prediction)
    | Predictions Json.Value
    | GeoLocation Json.Value
    | FetchStopsError String
    | FetchStopsSuccess StopsDocument

-- VIEW

view : Model -> Html Msg
view model =
  div []
      [ button [ onClick RequestGeoLocation ] [ text "Show nearby stops" ]
      , renderStops model
      ]

renderStops : Model -> Html Msg
renderStops model =
  div [] (List.map renderStop model.possibleStops)

renderStop : Stop -> Html Msg
renderStop stop =
  div [] [ text stop.commonName ]

oldView : Model -> Html Msg
oldView model =
  let
    sortedPredictions = List.sortBy .timeToStation <| Dict.values model.predictions
  in
    div []
        [ input [ onInput UpdateNaptanId, placeholder "Naptan ID" ] []
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
          Http.get url initialPredictionsDecoder
            |> Http.send handlePredictionsResponse )

    InitialPredictionsSuccess listOfPredictions ->
      ( updatePredictions model listOfPredictions, registerForLivePredictions model.naptanId )

    InitialPredictionsError message ->
      let
        _ = Debug.log "Predictions request failed" message
      in
        (model, Cmd.none)

    Predictions newPredictionsJson ->
      ( updatePredictions model <| decodePredictions newPredictionsJson, Cmd.none )

    RequestGeoLocation ->
      ( model, requestGeoLocation "" )

    GeoLocation geoLocationJson ->
      let
        geoLocation = decodeGeoLocation geoLocationJson
        _ = Debug.log "GeoLocation" geoLocation.lat
        url =
          "https://api.tfl.gov.uk/StopPoint?lat=" ++ (toString geoLocation.lat) ++ "&lon=" ++ (toString geoLocation.long) ++ "&stopTypes=NaptanPublicBusCoachTram&radius=200&useStopPointHierarchy=True&returnLines=True&app_id=&app_key=&modes=bus"
      in
        ( model,
          Http.get url stopPointsDecoder
            |> Http.send handleStopsResponse )

    FetchStopsSuccess stopsDocument ->
      let
        _ = Debug.log "Success" stopsDocument
      in
         ( { model | possibleStops = stopsDocument.stopPoints }, Cmd.none )

    FetchStopsError message ->
      let
        _ = Debug.log "error" message
      in
         ( model, Cmd.none )

handleStopsResponse : Result Http.Error (StopsDocument) -> Msg
handleStopsResponse result =
  case result of
    Ok stopsDocument -> FetchStopsSuccess stopsDocument
    Err msg -> FetchStopsError (toString msg)

handlePredictionsResponse : Result Http.Error (List Prediction) -> Msg
handlePredictionsResponse result =
  case result of
    Ok prediction -> InitialPredictionsSuccess prediction
    Err msg -> InitialPredictionsError (toString msg)

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [
    predictions Predictions,
    geoLocation GeoLocation
  ]

-- MAIN

main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
