module StopDecoder exposing (decodeStop)

import Debug
import Json.Decode exposing (Decoder, decodeValue, int, list, string, succeed)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Json
import Prediction exposing (Prediction)
import Stop exposing (Stop)


decodeStop : Json.Value -> Stop
decodeStop json =
    case decodeValue stopDecoder json of
        Ok val ->
            val

        Err msg ->
            Debug.crash msg


stopDecoder : Decoder Stop
stopDecoder =
    succeed Stop
        |> required "nap" string
        |> required "TimeToStation" int
        |> required "DestinationName" string
        |> required "VehicleId" string


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
