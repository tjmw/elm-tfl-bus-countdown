module NaptanId exposing (NaptanId, toString, fromString)


type NaptanId
    = NaptanId String


toString : NaptanId -> String
toString (NaptanId string) =
    string


fromString : String -> NaptanId
fromString =
    NaptanId
