module StopPointsDecoder exposing (stopPointsDecoder)

import Json.Encode as Json
import Json.Decode exposing (at, list, string, Decoder)
import Json.Decode.Pipeline exposing (decode, required)

import StopsDocument exposing (StopsDocument)
import Stop exposing (Stop)

stopPointsDecoder : Decoder StopsDocument
stopPointsDecoder =
  decode StopsDocument
    |> required "stopPoints" (list stopPointDecoder)

stopPointDecoder : Decoder Stop
stopPointDecoder =
  decode Stop
    |> required "naptanId" string
    |> required "commonName" string
    |> required "indicator" string
