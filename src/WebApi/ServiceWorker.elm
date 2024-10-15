module WebApi.ServiceWorker exposing (register, checkForUpdate, applyUpdate, Model, initModel, subscriptions, controllerChangeSub, OutMsg, Msg, update, isWaiting)

{-| WIP: Not working

TODO: docs

@docs register, checkForUpdate, applyUpdate, Model, initModel, subscriptions, controllerChangeSub, OutMsg, Msg, update, isWaiting

-}

import Browser.Navigation
import Json.Decode as JsonD
import Json.Encode as JsonE
import Task exposing (Task)
import WebApi.Browser as Browser
import WebApi.Console as Console
import WebApi.JavaScript as JavaScript
import WebApi.Window as Window



--


{-| TODO: docs
-}
register : String -> Cmd Msg
register serviceWorkerUrl =
    (\() ->
        JavaScript.callNested2 Browser.navigator
            "serviceWorker"
            "register"
            [ JsonE.string serviceWorkerUrl ]
            |> JavaScript.promise
            |> Task.andThen
                (\arguments ->
                    case
                        JsonD.decodeValue
                            (JsonD.field "0" JsonD.value)
                            arguments
                    of
                        Err err ->
                            [ ( "name"
                              , JsonE.string "ServiceWorker.register"
                              )
                            , ( "message"
                              , JsonE.string <| JsonD.errorToString err
                              )
                            ]
                                |> JsonE.object
                                |> Task.fail

                        Ok registration ->
                            Task.succeed registration
                )
    )
        |> JavaScript.try
        |> Task.andThen identity
        |> Task.attempt Registered


{-| TODO: docs
-}
checkForUpdate : Model -> Cmd Msg
checkForUpdate { registration } =
    case registration of
        Nothing ->
            Cmd.none

        Just reg ->
            (\() -> JavaScript.callNested reg "update" [])
                |> JavaScript.try
                |> Task.attempt CheckedForUpdate


{-| TODO: docs
-}
applyUpdate : Task JsonD.Value ()
applyUpdate =
    (\() ->
        JavaScript.callNested2 Browser.navigator
            "serviceWorker"
            "getRegistrations"
            []
            |> JavaScript.promise
            |> Task.andThen
                (\arguments ->
                    case
                        JsonD.decodeValue
                            (JsonD.field "0" (JsonD.list JsonD.value))
                            arguments
                    of
                        Err err ->
                            [ ( "name"
                              , JsonE.string "ServiceWorker.applyUpdate"
                              )
                            , ( "message"
                              , JsonE.string <| JsonD.errorToString err
                              )
                            ]
                                |> JsonE.object
                                |> Task.fail

                        Ok rgs ->
                            List.filterMap
                                (\rg ->
                                    if isWaiting rg then
                                        (\() ->
                                            JavaScript.callNested2 rg
                                                "waiting"
                                                "postMessage"
                                                [ JsonE.string "SKIP_WAITING" ]
                                        )
                                            |> JavaScript.try
                                            |> Just

                                    else
                                        Nothing
                                )
                                rgs
                                |> Task.sequence
                                |> Task.map (\_ -> ())
                )
    )
        |> JavaScript.try
        |> Task.andThen identity


{-| TODO: docs
-}
type alias Model =
    { isRefreshing : Bool
    , registration : Maybe JsonD.Value
    }


{-| TODO: docs
-}
initModel : Model
initModel =
    { isRefreshing = False
    , registration = Nothing
    }


{-| TODO: docs
-}
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ case model.registration of
            Nothing ->
                Sub.none

            Just registration ->
                let
                    maybeInstalling =
                        JavaScript.property registration "installing"
                            |> Maybe.andThen
                                (\i ->
                                    if JavaScript.isNull i then
                                        Nothing

                                    else
                                        Just i
                                )
                in
                case maybeInstalling of
                    Nothing ->
                        JavaScript.on registration
                            "updatefound"
                            (JsonD.succeed ChangedController)

                    Just installing ->
                        JavaScript.on installing
                            "statechange"
                            (JsonD.at [ "target", "state" ] JsonD.string
                                |> JsonD.map ChangedInstallingState
                            )
        , controllerChangeSub
        ]


{-| TODO: docs
-}
controllerChangeSub : Sub Msg
controllerChangeSub =
    JavaScript.property Browser.navigator "serviceWorker"
        |> Maybe.map
            (\sw -> JavaScript.on sw "controllerchange" (JsonD.succeed ChangedController))
        |> Maybe.withDefault Sub.none


{-| TODO: docs
-}
type OutMsg
    = NoOutMsg
    | RegistrationSucceed
    | RegistrationFailed JsonD.Value
    | UpdateReady


{-| TODO: docs
-}
type Msg
    = Registered (Result JsonD.Value JsonD.Value)
    | ChangedController
    | CheckedForUpdate (Result JsonD.Value JsonD.Value)
    | ChangedInstallingState String


{-| TODO: docs
-}
update : Msg -> Model -> ( ( Model, Cmd Msg, OutMsg ), List String )
update msg model =
    case msg of
        Registered (Ok registration) ->
            let
                alreadyHasController =
                    JavaScript.property Browser.navigator "serviceWorker"
                        |> Maybe.andThen (\sw -> JavaScript.property sw "controller")
                        |> Maybe.map JavaScript.isNull
                        |> Maybe.withDefault False

                updtModel =
                    { model | registration = Just registration }
            in
            ( if alreadyHasController then
                if isWaiting registration then
                    ( updtModel
                    , Cmd.none
                    , UpdateReady
                    )

                else
                    ( updtModel
                    , checkForUpdate updtModel
                    , RegistrationSucceed
                    )

              else
                -- The window client isn't currently controlled so it's a new
                -- service worker that will activate immediately
                ( updtModel, Cmd.none, RegistrationSucceed )
            , [ "Registered", "Ok" ]
            )

        Registered (Err err) ->
            ( ( model
              , Cmd.none
              , RegistrationFailed err
              )
            , [ "Registered", "Err" ]
            )

        ChangedController ->
            ( if model.isRefreshing then
                ( model, Cmd.none, NoOutMsg )

              else
                ( { model | isRefreshing = True }
                , Browser.Navigation.reload
                , NoOutMsg
                )
            , [ "ChangedController" ]
            )

        CheckedForUpdate res ->
            ( ( model, Cmd.none, NoOutMsg ), [ "CheckedForUpdate" ] )

        ChangedInstallingState state ->
            ( ( model
              , Cmd.none
              , case state of
                    "installed" ->
                        UpdateReady

                    _ ->
                        NoOutMsg
              )
            , [ "ChangedInstallingState", state ]
            )


{-| TODO: docs
-}
isWaiting : JsonD.Value -> Bool
isWaiting registration =
    JavaScript.property registration "waiting"
        |> Maybe.map (JavaScript.isNull >> not)
        |> Maybe.withDefault False
