module PredictionDecoder exposing (decodePredictions, initialPredictionsDecoder, predictionsDecoder)

import Debug
import Iso8601
import Json.Decode exposing (Decoder, decodeValue, fail, int, list, string, succeed)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Json
import Prediction exposing (Prediction)
import Time exposing (Posix)


decodePredictions : Json.Value -> List Prediction
decodePredictions json =
    case decodeValue predictionsDecoder json of
        Ok val ->
            val

        Err msg ->
            []



-- Note: The initial predictions fetch over HTTP has camel case key names with
-- lowercase first letters. The websocket stream has camelcase keys with
-- uppercase first letters :-/


predictionsDecoder : Decoder (List Prediction)
predictionsDecoder =
    list predictionDecoder


predictionDecoder : Decoder Prediction
predictionDecoder =
    succeed Prediction
        |> required "LineName" string
        |> required "TimeToStation" int
        |> required "DestinationName" string
        |> required "VehicleId" string
        |> required "TimeToLive" dateDecoder


initialPredictionsDecoder : Decoder (List Prediction)
initialPredictionsDecoder =
    list initialPredictionDecoder


initialPredictionDecoder : Decoder Prediction
initialPredictionDecoder =
    succeed Prediction
        |> required "lineName" string
        |> required "timeToStation" int
        |> required "destinationName" string
        |> required "vehicleId" string
        |> required "timeToLive" dateDecoder


dateDecoder : Decoder Posix
dateDecoder =
    string |> Json.Decode.andThen decodeDate


decodeDate : String -> Decoder Posix
decodeDate string =
    case Iso8601.toTime string of
        Ok time ->
            succeed time

        Err error ->
            fail "Bleurgh"
