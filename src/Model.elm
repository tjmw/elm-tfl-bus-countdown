module Model exposing (Model, emptyModel)

import Dict exposing(Dict)
import Prediction exposing(Prediction)

type alias Model =
  { naptanId : String
  , predictions : Dict String Prediction
  }

emptyModel = Model "" Dict.empty
