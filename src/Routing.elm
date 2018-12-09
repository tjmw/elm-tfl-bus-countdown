module Routing exposing (RoutePath, fromLocation)

import List exposing (drop)
import Url


type alias RoutePath =
    List String


fromLocation : Url.Url -> RoutePath
fromLocation { fragment } =
    fragment |> Maybe.map (String.split "/" >> drop 1) |> Maybe.withDefault []
