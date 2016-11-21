module Prediction exposing (Prediction)

type alias Prediction =
  {
    lineName : String,
    timeToStation : Int,
    destinationName : String,
    vehicleId : String
  }
