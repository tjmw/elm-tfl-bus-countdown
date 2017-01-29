module Routing exposing (RoutePath, fromLocation)

import List exposing (drop)
import Navigation


type alias RoutePath =
    List String


fromLocation : Navigation.Location -> RoutePath
fromLocation { hash } =
    hash |> String.split "/" |> drop 1
