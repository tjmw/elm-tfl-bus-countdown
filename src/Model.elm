module Model exposing (Model, State(..), resetModel)

import Dict exposing (Dict)
import NaptanId exposing (NaptanId)
import Navigation
import Prediction exposing (Prediction)
import Stop exposing (Stop)


type State
    = Initial
    | Error
    | FetchingGeoLocation
    | GeoLocationError
    | LoadingStops
    | ShowingStops
    | LoadingPredictions
    | ShowingPredictions


type alias Model =
    { naptanId : Maybe NaptanId
    , predictions : Dict String Prediction
    , possibleStops : List Stop
    , state : State
    , tfl_app_id : String
    , tfl_app_key : String
    , currentRoute : Navigation.Location
    }


resetModel : Model -> Model
resetModel model =
    { model | naptanId = Nothing, predictions = Dict.empty, possibleStops = [], state = Initial }
