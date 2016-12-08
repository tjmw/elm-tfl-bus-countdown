module Main exposing (..)

import Dict exposing(Dict)
import Html exposing (Html, div, span, text, button, input, table, tr, td)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (placeholder, class)
import Http
import Json.Encode as Json
import String
import Task exposing (Task)

import Model exposing (Model, emptyModel)
import Ports exposing (registerForLivePredictions, deregisterFromLivePredictions, predictions, requestGeoLocation, geoLocation)
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
    | RequestGeoLocation
    | InitialPredictionsError String
    | InitialPredictionsSuccess (List Prediction)
    | Predictions Json.Value
    | GeoLocation Json.Value
    | FetchStopsError String
    | FetchStopsSuccess StopsDocument
    | BackToStops

-- VIEW

view : Model -> Html Msg
view model =
  div []
      [ button [ onClick RequestGeoLocation ] [ text "Show nearby stops" ]
      , if model.naptanId /= "" then renderPredictions model else renderStops model
      ]

renderStops : Model -> Html Msg
renderStops model =
  div [] (List.map renderStop model.possibleStops)

renderStop : Stop -> Html Msg
renderStop stop =
  div [ class "stop", onClick (UpdateNaptanId stop.naptanId) ]
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
    sortedPredictions = List.sortBy .timeToStation <| Dict.values model.predictions
  in
    div [] [
      table [] (List.map renderPrediction sortedPredictions)
      , renderBackToStops
    ]

renderPrediction : Prediction -> Html Msg
renderPrediction prediction =
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
      let
        url =
          "https://api.tfl.gov.uk/StopPoint/" ++ newNaptanId ++ "/Arrivals?mode=bus"
      in
        ( { model | naptanId = newNaptanId },
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
      let
        unsubscribeCmd = if model.naptanId /= "" then deregisterFromLivePredictions model.naptanId
                         else Cmd.none

        cmd = Cmd.batch [ unsubscribeCmd, (requestGeoLocation "") ]
      in
        ( emptyModel, cmd )

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

    BackToStops ->
      ( { model | predictions = Dict.empty, naptanId = "" }, deregisterFromLivePredictions model.naptanId )

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
