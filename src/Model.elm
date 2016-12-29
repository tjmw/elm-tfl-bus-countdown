module Model exposing (Model, State(..), emptyModel, resetModel)

import Dict exposing (Dict)
import Prediction exposing (Prediction)
import Stop exposing (Stop)


type State
    = Initial
    | Error
    | FetchingGeoLocation
    | LoadingStops
    | ShowingStops
    | LoadingPredictions
    | ShowingPredictions


type alias Model =
    { naptanId : String
    , predictions : Dict String Prediction
    , possibleStops : List Stop
    , state : State
    , tfl_app_id : String
    , tfl_app_key : String
    }


emptyModel =
    Model "" Dict.empty [] Initial "" ""


resetModel model =
    { emptyModel | tfl_app_id = model.tfl_app_id, tfl_app_key = model.tfl_app_key }
