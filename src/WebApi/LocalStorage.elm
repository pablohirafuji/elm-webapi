module WebApi.LocalStorage exposing (Error(..), clear, entries, errorToString, getItem, key, length, removeItem, setItem)

{-| TODO: Docs

@docs Error, clear, entries, errorToString, getItem, key, length, removeItem, setItem

-}

import Dict exposing (Dict)
import Elm.Kernel.LocalStorage
import Task exposing (Task)


{-| TODO: docs
-}
key : Int -> Task Error String
key =
    Elm.Kernel.LocalStorage.key


{-| TODO: docs
-}
getItem : String -> Task Error String
getItem =
    Elm.Kernel.LocalStorage.getItem


{-| TODO: docs
-}
removeItem : String -> Task Error ()
removeItem =
    Elm.Kernel.LocalStorage.removeItem


{-| TODO: docs
-}
setItem : String -> String -> Task Error ()
setItem =
    Elm.Kernel.LocalStorage.setItem


{-| TODO: docs
-}
length : Task x Int
length =
    Elm.Kernel.LocalStorage.length


{-| TODO: docs
-}
clear : Task Error ()
clear =
    Elm.Kernel.LocalStorage.clear


{-| TODO: docs
-}
entries : Task Error (Dict String String)
entries =
    Task.andThen
        (\l ->
            List.range 0 (l - 1)
                |> List.map
                    (key
                        >> Task.andThen
                            (\k ->
                                getItem k
                                    |> Task.map (Tuple.pair k)
                            )
                    )
                |> Task.sequence
                |> Task.map Dict.fromList
        )
        length


{-| TODO: docs
-}
type Error
    = NotFound
    | NotSupported
    | QuotaExceeded


{-| TODO: docs
-}
errorToString : Error -> String
errorToString error =
    case error of
        NotFound ->
            "NotFound"

        NotSupported ->
            "NotSupported"

        QuotaExceeded ->
            "QuotaExceeded"
