module Loading exposing (toggleLoading)

import Model exposing (Model)


toggleLoading : Model -> Model
toggleLoading model =
    { model | loading = not model.loading }
