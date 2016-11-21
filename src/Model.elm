module Model exposing (Model, emptyModel)

import Prediction exposing(Prediction)

type alias Model =
  { naptanId : String
  , predictions : List Prediction
  }

emptyModel = Model "" []
