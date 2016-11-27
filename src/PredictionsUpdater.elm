module PredictionsUpdater exposing (updatePredictions)

import Dict exposing (Dict)
import Json.Encode as Json
import List
import Model exposing (Model)
import PredictionDecoder exposing (decodePredictions)

updatePredictions : Model -> Json.Value -> Model
updatePredictions model json =
  let
    decodedPredictions = decodePredictions json
    newpredictionsDict = listToDict .vehicleId decodedPredictions
    predictionsDict = Dict.union newpredictionsDict model.predictions
  in
    { model | predictions = predictionsDict }

listToDict : (a -> comparable) -> List a -> Dict comparable a
listToDict getKey values =
  Dict.fromList (List.map (\v -> (getKey v, v)) values)
