module PredictionsUpdater exposing (updatePredictions)

import Json.Encode as Json
import Model exposing (Model)
import PredictionDecoder exposing (decodePredictions)

updatePredictions : Model -> Json.Value -> Model
updatePredictions model json =
  { model | predictions = (decodePredictions json) }
