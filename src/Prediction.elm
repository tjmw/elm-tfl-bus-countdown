module Prediction exposing (Prediction, secondsToMinutes)

import Time


type alias Prediction =
    { lineName : String
    , timeToStation : Int
    , destinationName : String
    , vehicleId : String
    , timeToLive : Time.Posix
    }


secondsToMinutes : Int -> Int
secondsToMinutes seconds =
    seconds // 60
