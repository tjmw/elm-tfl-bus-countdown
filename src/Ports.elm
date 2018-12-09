port module Ports exposing (deregisterFromLivePredictions, geoLocation, geoLocationUnavailable, predictions, registerForLivePredictions, requestGeoLocation)

import Json.Encode as Json
import NaptanId exposing (NaptanId)



-- Live predictions stream ports


port registerForLivePredictions : String -> Cmd msg


port deregisterFromLivePredictions : String -> Cmd msg


port predictions : (Json.Value -> msg) -> Sub msg



-- Geo location ports


port requestGeoLocation : String -> Cmd msg


port geoLocation : (Json.Value -> msg) -> Sub msg


port geoLocationUnavailable : (String -> msg) -> Sub msg
