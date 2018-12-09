module StopPointsDecoder exposing (stopPointsDecoder)

import Json.Decode exposing (Decoder, at, list, string)
import Json.Decode.Pipeline exposing (decode, required)
import Json.Encode as Json
import Line exposing (Line)
import Stop exposing (Stop)
import StopProperty exposing (StopProperty)
import StopsDocument exposing (StopsDocument)


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
        |> required "additionalProperties" (list stopPropertyDecoder)
        |> required "lines" (list lineDecoder)


stopPropertyDecoder : Decoder StopProperty
stopPropertyDecoder =
    decode StopProperty
        |> required "category" string
        |> required "key" string
        |> required "value" string


lineDecoder : Decoder Line
lineDecoder =
    decode Line
        |> required "name" string
