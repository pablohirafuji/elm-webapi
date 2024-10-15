module WebApi.Browser exposing (self, document, window, navigator, focusQuerySelector, querySelector, focus)

{-| TODO: Docs

@docs self, document, window, navigator, focusQuerySelector, querySelector, focus

-}

import Elm.Kernel.BrowserCustom
import Json.Decode as JsonD
import Json.Encode as JsonE
import Task exposing (Task)
import WebApi.JavaScript as JavaScript
import WebApi.Window as Window


{-| TODO: docs
-}
self : JsonD.Value
self =
    Elm.Kernel.BrowserCustom.self


{-| TODO: docs
-}
document : JsonD.Value
document =
    Elm.Kernel.BrowserCustom.document


{-| TODO: docs
-}
window : JsonD.Value
window =
    Elm.Kernel.BrowserCustom.window


{-| TODO: docs
-}
navigator : JsonD.Value
navigator =
    Elm.Kernel.BrowserCustom.navigator


{-| TODO: docs
-}
focusQuerySelector : String -> Task () (Maybe JsonD.Value)
focusQuerySelector query =
    JavaScript.property document "activeElement"
        |> Window.requestAnimationFrame
        |> Task.andThen
            (\activeElement ->
                querySelector query
                    |> Task.andThen focus
                    |> Task.map (\_ -> activeElement)
            )


{-| TODO: docs
-}
querySelector : String -> Task () JsonD.Value
querySelector query =
    let
        maybeElem =
            JavaScript.callNested document "querySelector" [ JsonE.string query ]
    in
    if JavaScript.isNull maybeElem then
        Task.fail ()

    else
        Task.succeed maybeElem


{-| TODO: docs
-}
focus : JsonD.Value -> Task () ()
focus elem =
    JavaScript.try (\() -> JavaScript.callNested elem "focus" [])
        |> Task.map (\_ -> ())
        |> Task.mapError (\_ -> ())
