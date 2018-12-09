module GeoLocationDecoder exposing (decodeGeoLocation)

import GeoLocation exposing (GeoLocation)
import Json.Decode exposing (Decoder, decodeValue, float)
import Json.Decode.Pipeline exposing (decode, required)
import Json.Encode as Json


decodeGeoLocation : Json.Value -> GeoLocation
decodeGeoLocation json =
    case decodeValue geoLocationDecoder json of
        Ok val ->
            val

        Err msg ->
            Debug.crash msg


geoLocationDecoder : Decoder GeoLocation
geoLocationDecoder =
    decode GeoLocation
        |> required "lat" float
        |> required "long" float
