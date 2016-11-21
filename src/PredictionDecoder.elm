module PredictionDecoder exposing (decodePredictions)

import Json.Encode as Json
import Json.Decode exposing (decodeValue, list, int, string, Decoder)
import Json.Decode.Pipeline exposing (decode, required)

import Prediction exposing (Prediction)

decodePredictions : Json.Value -> List Prediction
decodePredictions json =
  case decodeValue (list predictionDecoder) json of
    Ok val -> val
    Err msg -> Debug.crash msg

predictionDecoder : Decoder Prediction
predictionDecoder =
  decode Prediction
    |> required "LineName" string
    |> required "TimeToStation" int
    |> required "DestinationName" string
    |> required "VehicleId" string
