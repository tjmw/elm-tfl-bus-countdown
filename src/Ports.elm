port module Ports exposing(registerForLivePredictions, predictions)

import Json.Encode as Json

port registerForLivePredictions : String -> Cmd msg
port predictions : (Json.Value -> msg) -> Sub msg
