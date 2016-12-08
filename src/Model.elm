module Model exposing (Model, emptyModel)

import Dict exposing(Dict)
import Prediction exposing(Prediction)
import Stop exposing(Stop)

type alias Model =
  { naptanId : String
  , predictions : Dict String Prediction
  , possibleStops : List Stop
  }

emptyModel = Model "" Dict.empty []
