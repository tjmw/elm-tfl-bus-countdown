module StopDecoder exposing (decodeStop)

import Json.Encode as Json
import Json.Decode exposing (decodeValue, list, int, string, Decoder)
import Json.Decode.Pipeline exposing (decode, required)
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
    decode Stop
        |> required "nap" string
        |> required "TimeToStation" int
        |> required "DestinationName" string
        |> required "VehicleId" string


initialPredictionsDecoder : Decoder (List Prediction)
initialPredictionsDecoder =
    list initialPredictionDecoder


initialPredictionDecoder : Decoder Prediction
initialPredictionDecoder =
    decode Prediction
        |> required "lineName" string
        |> required "timeToStation" int
        |> required "destinationName" string
        |> required "vehicleId" string
