port module Ports exposing(registerForPredictions, predictions)

port registerForPredictions : String -> Cmd msg
port predictions : (List String -> msg) -> Sub msg
