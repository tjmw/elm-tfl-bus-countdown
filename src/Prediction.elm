module Prediction exposing (Prediction, secondsToMinutes)

import Date exposing (Date)


type alias Prediction =
    { lineName : String
    , timeToStation : Int
    , destinationName : String
    , vehicleId : String
    , timeToLive : Date
    }


secondsToMinutes : Int -> Int
secondsToMinutes seconds =
    seconds // 60
