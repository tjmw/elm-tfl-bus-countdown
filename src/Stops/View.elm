module Stops.View exposing (view)

import Html exposing (Html, div, span, text)
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
    div [] (List.map renderStop model.possibleStops)


renderStop : Stop -> Html Msg
renderStop stop =
    div [ class "stop", onClick (Stops.State.SelectStop stop.naptanId) ]
        [ span [] [ text stop.naptanId ]
        , span [] [ text stop.indicator ]
        , span [] [ text stop.commonName ]
        ]
