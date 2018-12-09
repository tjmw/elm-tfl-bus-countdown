module StopPointsDecoder exposing (stopPointsDecoder)

import Json.Decode exposing (Decoder, at, list, string, succeed)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Json
import Line exposing (Line)
import Stop exposing (Stop)
import StopProperty exposing (StopProperty)
import StopsDocument exposing (StopsDocument)


stopPointsDecoder : Decoder StopsDocument
stopPointsDecoder =
    succeed StopsDocument
        |> required "stopPoints" (list stopPointDecoder)


stopPointDecoder : Decoder Stop
stopPointDecoder =
    succeed Stop
        |> required "naptanId" string
        |> required "commonName" string
        |> required "indicator" string
        |> required "additionalProperties" (list stopPropertyDecoder)
        |> required "lines" (list lineDecoder)


stopPropertyDecoder : Decoder StopProperty
stopPropertyDecoder =
    succeed StopProperty
        |> required "category" string
        |> required "key" string
        |> required "value" string


lineDecoder : Decoder Line
lineDecoder =
    succeed Line
        |> required "name" string
