port module Ports exposing(registerForPredictions, predictions)

import Json.Encode as Json

port registerForPredictions : String -> Cmd msg
port predictions : (Json.Value -> msg) -> Sub msg
