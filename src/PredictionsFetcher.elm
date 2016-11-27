module PredictionsFetcher exposing (fetchInitialPredictions)

import Http
import Task exposing (Task)

import Prediction exposing (Prediction)
import PredictionDecoder exposing (predictionsDecoder)

fetchInitialPredictions : String -> Task Http.Error (List Prediction)
fetchInitialPredictions naptanId =
  let
    url =
      "https://api.tfl.gov.uk/StopPoint/" ++ naptanId ++ "/Arrivals?mode=bus"
  in
    Http.get predictionsDecoder url
