effect module WebApi.Window where { subscription = MySub } exposing (custom, on, preventDefaultOn, requestAnimationFrame, stopPropagationOn)

{-| TODO: Docs

@docs custom, on, preventDefaultOn, requestAnimationFrame, stopPropagationOn

-}

import Dict
import Elm.Kernel.Window
import Json.Decode as JsonD
import Process
import Task exposing (Task)
import Time


{-| TODO: docs
-}
requestAnimationFrame : a -> Task x a
requestAnimationFrame =
    Elm.Kernel.Window.requestAnimationFrame



-- SUBSCRIPTIONS
-- From https://github.com/elm/virtual-dom/blob/master/src/VirtualDom.elm


{-| TODO: docs
-}
on : String -> JsonD.Decoder msg -> Sub msg
on event decoder =
    subscription (MySub event (Normal decoder))


{-| TODO: docs
-}
stopPropagationOn : String -> JsonD.Decoder ( msg, Bool ) -> Sub msg
stopPropagationOn event decoder =
    subscription (MySub event (MayStopPropagation decoder))


{-| TODO: docs
-}
preventDefaultOn : String -> JsonD.Decoder ( msg, Bool ) -> Sub msg
preventDefaultOn event decoder =
    subscription (MySub event (MayPreventDefault decoder))


{-| TODO: docs
-}
custom : String -> JsonD.Decoder { message : msg, stopPropagation : Bool, preventDefault : Bool } -> Sub msg
custom event decoder =
    subscription (MySub event (Custom decoder))


type MySub msg
    = MySub String (Handler msg)


type Handler msg
    = Normal (JsonD.Decoder msg)
    | MayStopPropagation (JsonD.Decoder ( msg, Bool ))
    | MayPreventDefault (JsonD.Decoder ( msg, Bool ))
    | Custom (JsonD.Decoder { message : msg, stopPropagation : Bool, preventDefault : Bool })


toHandlerInt : Handler msg -> Int
toHandlerInt handler =
    case handler of
        Normal _ ->
            0

        MayStopPropagation _ ->
            1

        MayPreventDefault _ ->
            2

        Custom _ ->
            3


subMap : (a -> b) -> MySub a -> MySub b
subMap func (MySub event handler) =
    MySub event <|
        case handler of
            Normal decoder ->
                Normal (JsonD.map func decoder)

            MayStopPropagation decoder ->
                MayStopPropagation (JsonD.map (Tuple.mapFirst func) decoder)

            MayPreventDefault decoder ->
                MayPreventDefault (JsonD.map (Tuple.mapFirst func) decoder)

            Custom decoder ->
                Custom
                    (JsonD.map
                        (\r ->
                            { message = func r.message
                            , stopPropagation = r.stopPropagation
                            , preventDefault = r.preventDefault
                            }
                        )
                        decoder
                    )



-- EFFECT MANAGER


type alias State msg =
    { subs : List ( String, MySub msg )
    , pids : Dict.Dict String Process.Id
    }


init : Task Never (State msg)
init =
    Task.succeed (State [] Dict.empty)


type alias Event msg =
    { key : String
    , event : Maybe msg
    }


onSelfMsg : Platform.Router msg (Event msg) -> Event msg -> State msg -> Task Never (State msg)
onSelfMsg router { key, event } state =
    let
        toMessage ( subKey, MySub name handler ) =
            if subKey == key then
                event

            else
                Nothing

        messages =
            List.filterMap toMessage state.subs
    in
    Task.sequence (List.map (Platform.sendToApp router) messages)
        |> Task.andThen (\_ -> Task.succeed state)


onEffects : Platform.Router msg (Event msg) -> List (MySub msg) -> State msg -> Task Never (State msg)
onEffects router subs state =
    let
        newSubs =
            List.map addKey subs

        stepLeft _ pid ( deads, lives, news ) =
            ( pid :: deads, lives, news )

        stepBoth key pid _ ( deads, lives, news ) =
            ( deads, Dict.insert key pid lives, news )

        stepRight key sub ( deads, lives, news ) =
            ( deads, lives, spawn router key sub :: news )

        ( deadPids, livePids, makeNewPids ) =
            Dict.merge stepLeft stepBoth stepRight state.pids (Dict.fromList newSubs) ( [], Dict.empty, [] )
    in
    Task.sequence (List.map Process.kill deadPids)
        |> Task.andThen (\_ -> Task.sequence makeNewPids)
        |> Task.andThen (\pids -> Task.succeed (State newSubs (Dict.union livePids (Dict.fromList pids))))



-- TO KEY


addKey : MySub msg -> ( String, MySub msg )
addKey ((MySub name _) as sub) =
    ( name, sub )



-- SPAWN


spawn : Platform.Router msg (Event msg) -> String -> MySub msg -> Task Never ( String, Process.Id )
spawn router key (MySub name handler) =
    Task.map (\value -> ( key, value )) <|
        Elm.Kernel.Window.on name handler <|
            \event -> Platform.sendToSelf router (Event key event)
