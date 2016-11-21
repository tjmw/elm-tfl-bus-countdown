module Model exposing (Model, emptyModel)

type alias Model =
  { naptanId : String
  , predictions : List String
  }

emptyModel = Model "" []
