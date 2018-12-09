module GeoLocationDecoder exposing (decodeGeoLocation)

import GeoLocation exposing (GeoLocation(..), toGeoLocation)
import Json.Decode exposing (Decoder, decodeValue, float, succeed)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Json


decodeGeoLocation : Json.Value -> GeoLocation
decodeGeoLocation json =
    case decodeValue geoLocationDecoder json of
        Ok val ->
            val

        Err msg ->
            GeoLocationFailure


geoLocationDecoder : Decoder GeoLocation
geoLocationDecoder =
    succeed toGeoLocation
        |> required "lat" float
        |> required "long" float
