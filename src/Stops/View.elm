module Stops.View exposing (view)

import Html exposing (Html, div, table, tr, td, text)
import Html.Events exposing (onClick)
import Html.Attributes exposing (class)
import Model exposing (Model)
import Stop exposing (Stop)
import Stops.State exposing (Msg)


view : Model -> Html Msg
view model =
    renderStops model


renderStops : Model -> Html Msg
renderStops model =
    table [ class "pure-table pure-table-horizontal clickable-table" ] (List.map renderStop model.possibleStops)


renderStop : Stop -> Html Msg
renderStop stop =
    tr [ class "stop", onClick (Stops.State.SelectStop stop.naptanId) ]
        [ td [] [ text stop.naptanId ]
        , td [] [ text stop.indicator ]
        , td [] [ text stop.commonName ]
        ]
