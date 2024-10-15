module WebApi.Console exposing (error, group, groupCollapsed, groupEnd, info, log, profile, profileEnd, warn)

{-| TODO: Docs

@docs error, group, groupCollapsed, groupEnd, info, log, profile, profileEnd, warn

-}

import Elm.Kernel.Console


{-| TODO: docs
-}
error : a -> a
error =
    Elm.Kernel.Console.error


{-| TODO: docs
-}
group : a -> a
group =
    Elm.Kernel.Console.group


{-| TODO: docs
-}
groupCollapsed : a -> a
groupCollapsed =
    Elm.Kernel.Console.groupCollapsed


{-| TODO: docs
-}
groupEnd : ()
groupEnd =
    Elm.Kernel.Console.groupEnd


{-| TODO: docs
-}
info : a -> a
info =
    Elm.Kernel.Console.info


{-| TODO: docs
-}
log : a -> a
log =
    Elm.Kernel.Console.log


{-| TODO: docs
-}
warn : a -> a
warn =
    Elm.Kernel.Console.warn


{-| TODO: docs
-}
profile : String
profile =
    Elm.Kernel.Console.profile


{-| TODO: docs
-}
profileEnd : String
profileEnd =
    Elm.Kernel.Console.profileEnd
