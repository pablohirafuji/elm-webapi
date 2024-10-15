module WebApi.Crypto exposing (getRandomBytes, randomUUID, Error(..), errorToString)

{-| TODO: Docs

@docs getRandomBytes, randomUUID, Error, errorToString

-}

import Bytes exposing (Bytes)
import Elm.Kernel.Crypto
import Task exposing (Task)


{-| TODO: docs
-}
getRandomBytes : Int -> Task Error Bytes
getRandomBytes =
    Elm.Kernel.Crypto.getRandomBytes


{-| TODO: docs
-}
randomUUID : Task Error String
randomUUID =
    Elm.Kernel.Crypto.randomUUID


{-| TODO: docs
-}
type Error
    = NotSupported
    | QuotaExceeded


{-| TODO: docs
-}
errorToString : Error -> String
errorToString error =
    case error of
        NotSupported ->
            "NotSupported"

        QuotaExceeded ->
            "QuotaExceeded"
