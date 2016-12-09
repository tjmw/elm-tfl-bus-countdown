module State exposing (..)

import Json.Encode as Json
import Time exposing (Time, second)

import Prediction exposing (Prediction)
import Stops.State

type Msg
    = NoOp
    | RequestGeoLocation
    | StopsMsg Stops.State.Msg
    | InitialPredictionsError String
    | InitialPredictionsSuccess (List Prediction)
    | Predictions Json.Value
    | BackToStops
    | PruneExpiredPredictions Time
