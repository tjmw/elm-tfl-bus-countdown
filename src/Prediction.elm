module Prediction exposing (Prediction, secondsToMinutes)

type alias Prediction =
  {
    lineName : String,
    timeToStation : Int,
    destinationName : String,
    vehicleId : String
  }

secondsToMinutes : Int -> Int
secondsToMinutes seconds =
  seconds // 60
