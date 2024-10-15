effect module WebApi.JavaScript where { subscription = MySub } exposing (Typeof(..), bytesDecoder, bytesToJson, globalThis, call, callNested, callNested2, callNested3, access, newCall, custom, functionArg, isNull, on, preventDefaultOn, promise, property, stopPropagationOn, try, typeof, typeofFromString)

{-| TODO: Docs

@docs Typeof, bytesDecoder, bytesToJson, globalThis, call, callNested, callNested2, callNested3, access, newCall, custom, functionArg, isNull, on, preventDefaultOn, promise, property, stopPropagationOn, try, typeof, typeofFromString

-}

import Bytes exposing (Bytes)
import Dict
import Elm.Kernel.JavaScript
import Json.Decode as JsonD
import Json.Encode as JsonE
import Process
import Task exposing (Task)
import Time


{-| TODO: docs
-}
bytesDecoder : JsonD.Value -> Bytes
bytesDecoder val =
    Elm.Kernel.JavaScript.bytesDecoder val


{-| TODO: docs
-}
bytesToJson : Bytes -> JsonD.Value
bytesToJson bytes =
    Elm.Kernel.JavaScript.bytesToJson bytes


{-| TODO: docs
-}
globalThis : JsonD.Value
globalThis =
    Elm.Kernel.JavaScript.globalThis


{-| TODO: docs
-}
call : JsonD.Value -> List JsonD.Value -> JsonD.Value
call fn args =
    Elm.Kernel.JavaScript.call fn (JsonE.list identity args)


{-| TODO: docs
-}
callNested : JsonD.Value -> String -> List JsonD.Value -> JsonD.Value
callNested obj at args =
    Elm.Kernel.JavaScript.callNested obj at (JsonE.list identity args)


{-| TODO: docs
-}
callNested2 : JsonD.Value -> String -> String -> List JsonD.Value -> JsonD.Value
callNested2 obj at1 at2 args =
    Elm.Kernel.JavaScript.callNested2 obj at1 at2 (JsonE.list identity args)


{-| TODO: docs
-}
callNested3 : JsonD.Value -> String -> String -> String -> List JsonD.Value -> JsonD.Value
callNested3 obj at1 at2 at3 args =
    Elm.Kernel.JavaScript.callNested3 obj at1 at2 at3 (JsonE.list identity args)


{-| TODO: docs
-}
access : JsonD.Value -> List String -> JsonD.Value
access obj at =
    Elm.Kernel.JavaScript.access obj (JsonE.list JsonE.string at)


{-| TODO: docs
-}
newCall : JsonD.Value -> List JsonD.Value -> JsonD.Value
newCall obj args =
    Elm.Kernel.JavaScript.newCall obj (JsonE.list identity args)


{-| TODO: docs
-}
promise : JsonD.Value -> Task JsonD.Value JsonD.Value
promise =
    Elm.Kernel.JavaScript.promise


{-| TODO: docs
-}
functionArg : (JsonD.Value -> a) -> JsonD.Value
functionArg =
    Elm.Kernel.JavaScript.functionArg


{-| TODO: docs
-}
property : JsonD.Value -> String -> Maybe JsonD.Value
property =
    Elm.Kernel.JavaScript.property


{-| TODO: docs
-}
try : (() -> a) -> Task JsonD.Value a
try =
    Elm.Kernel.JavaScript.try


{-| TODO: docs
-}
isNull : JsonD.Value -> Bool
isNull =
    Elm.Kernel.JavaScript.isNull


{-| TODO: docs
-}
typeof : JsonD.Value -> Typeof
typeof =
    Elm.Kernel.JavaScript.typeof
        >> typeofFromString



--From https://developer.mozilla.org/pt-BR/docs/Web/JavaScript/Reference/Operators/typeof#descri%C3%A7%C3%A3o


{-| TODO: docs
-}
typeofFromString : String -> Typeof
typeofFromString str =
    case str of
        "undefined" ->
            Undefined

        "object" ->
            Object

        "boolean" ->
            Boolean

        "number" ->
            Number

        "string" ->
            String

        "function" ->
            Function

        "xml" ->
            Xml

        _ ->
            HostObject str


{-| TODO: docs
-}
type Typeof
    = Undefined
    | Object
    | Boolean
    | Number
    | String
    | Function
    | Xml
    | HostObject String



-- SUBSCRIPTIONS
-- From https://github.com/elm/virtual-dom/blob/master/src/VirtualDom.elm


{-| TODO: docs
-}
on : JsonD.Value -> String -> JsonD.Decoder msg -> Sub msg
on target event decoder =
    subscription (MySub target event (Normal decoder))


{-| TODO: docs
-}
stopPropagationOn : JsonD.Value -> String -> JsonD.Decoder ( msg, Bool ) -> Sub msg
stopPropagationOn target event decoder =
    subscription (MySub target event (MayStopPropagation decoder))


{-| TODO: docs
-}
preventDefaultOn : JsonD.Value -> String -> JsonD.Decoder ( msg, Bool ) -> Sub msg
preventDefaultOn target event decoder =
    subscription (MySub target event (MayPreventDefault decoder))


{-| TODO: docs
-}
custom : JsonD.Value -> String -> JsonD.Decoder { message : msg, stopPropagation : Bool, preventDefault : Bool } -> Sub msg
custom target event decoder =
    subscription (MySub target event (Custom decoder))


type MySub msg
    = MySub JsonD.Value String (Handler msg)


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
subMap func (MySub target event handler) =
    MySub target event <|
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
        toMessage ( subKey, MySub target name handler ) =
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
addKey ((MySub target name _) as sub) =
    ( name, sub )



-- SPAWN


spawn : Platform.Router msg (Event msg) -> String -> MySub msg -> Task Never ( String, Process.Id )
spawn router key (MySub target name handler) =
    Task.map (\value -> ( key, value )) <|
        Elm.Kernel.JavaScript.addEventListener target name handler <|
            \event -> Platform.sendToSelf router (Event key event)
