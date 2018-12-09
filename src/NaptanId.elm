module NaptanId exposing (NaptanId, fromString, toString)


type NaptanId
    = NaptanId String


toString : NaptanId -> String
toString (NaptanId string) =
    string


fromString : String -> NaptanId
fromString =
    NaptanId
