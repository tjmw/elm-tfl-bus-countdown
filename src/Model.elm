module Model exposing (Model, State(..), resetModel)

import Browser.Navigation as Nav
import Dict exposing (Dict)
import NaptanId exposing (NaptanId)
import Prediction exposing (Prediction)
import Stop exposing (Stop)
import Url


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
    { key : Nav.Key
    , naptanId : Maybe NaptanId
    , predictions : Dict String Prediction
    , possibleStops : List Stop
    , state : State
    , tfl_app_id : String
    , tfl_app_key : String
    , currentRoute : Url.Url
    }


resetModel : Model -> Model
resetModel model =
    { model | naptanId = Nothing, predictions = Dict.empty, possibleStops = [], state = Initial }
