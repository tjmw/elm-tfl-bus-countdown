module Model exposing (Model, State(..), emptyModel)

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
    }


emptyModel =
    Model "" Dict.empty [] Initial
