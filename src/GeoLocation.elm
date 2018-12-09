module GeoLocation exposing (GeoLocation(..), fromGeoLocation, toGeoLocation)


type GeoLocation
    = GeoLocationSuccess Float Float
    | GeoLocationFailure


toGeoLocation : Float -> Float -> GeoLocation
toGeoLocation lat long =
    GeoLocationSuccess lat long


fromGeoLocation : GeoLocation -> Maybe ( Float, Float )
fromGeoLocation geoLocation =
    case geoLocation of
        GeoLocationSuccess lat long ->
            Just ( lat, long )

        GeoLocationFailure ->
            Nothing
