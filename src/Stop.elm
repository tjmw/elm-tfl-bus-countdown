module Stop exposing (Stop, compassDirection, towardsDirection)

import Line exposing (Line)
import StopProperty exposing (StopProperty)


type alias Stop =
    { naptanId : String
    , commonName : String
    , indicator : String
    , properties : List StopProperty
    , lines : List Line
    }


towardsDirection : Stop -> Maybe String
towardsDirection stop =
    stop.properties
        |> List.filter towardsDirectionFilter
        |> List.map .value
        |> List.head


towardsDirectionFilter : StopProperty -> Bool
towardsDirectionFilter prop =
    prop.category == "Direction" && prop.key == "Towards"


compassDirection : Stop -> Maybe String
compassDirection stop =
    stop.properties
        |> List.filter compassDirectionFilter
        |> List.map .value
        |> List.head


compassDirectionFilter : StopProperty -> Bool
compassDirectionFilter prop =
    prop.category == "Direction" && prop.key == "CompassPoint"
