module GeoLocationDecoder exposing (decodeGeoLocation)

import Json.Encode as Json
import Json.Decode exposing (decodeValue, float, Decoder)
import Json.Decode.Pipeline exposing (decode, required)

import GeoLocation exposing (GeoLocation)

decodeGeoLocation : Json.Value -> GeoLocation
decodeGeoLocation json =
  case decodeValue geoLocationDecoder json of
    Ok val -> val
    Err msg -> Debug.crash msg

geoLocationDecoder : Decoder GeoLocation
geoLocationDecoder =
  decode GeoLocation
    |> required "lat" float
    |> required "long" float
