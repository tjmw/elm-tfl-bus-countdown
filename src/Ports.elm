port module Ports exposing (registerForLivePredictions, deregisterFromLivePredictions, predictions, requestGeoLocation, geoLocation, geoLocationUnavailable)

import Json.Encode as Json


-- Live predictions stream ports


port registerForLivePredictions : String -> Cmd msg


port deregisterFromLivePredictions : String -> Cmd msg


port predictions : (Json.Value -> msg) -> Sub msg



-- Geo location ports


port requestGeoLocation : String -> Cmd msg


port geoLocation : (Json.Value -> msg) -> Sub msg


port geoLocationUnavailable : (String -> msg) -> Sub msg
