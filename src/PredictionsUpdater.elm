module PredictionsUpdater exposing (updatePredictions)

import Dict exposing (Dict)
import Json.Encode as Json
import List

import Model exposing (Model)
import Prediction exposing (Prediction)
import PredictionDecoder exposing (decodePredictions)

updatePredictions : Model -> (List Prediction) -> Model
updatePredictions model listOfPredictions =
  let
    newpredictionsDict = listToDict .vehicleId listOfPredictions
    predictionsDict = Dict.union newpredictionsDict model.predictions
  in
    { model | predictions = predictionsDict }

listToDict : (a -> comparable) -> List a -> Dict comparable a
listToDict getKey values =
  Dict.fromList (List.map (\v -> (getKey v, v)) values)
