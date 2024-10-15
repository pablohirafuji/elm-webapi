module WebApi.PageLifecycle exposing (init, Model, subscriptions, eventSubscriptions, addUnsavedChanges, removeUnsavedChanges, Msg, update, updateState, stateChanges, supportsPageTransitionEvents, events, State, stateToString, stateFromString, legalStateTransitions, legalStateTransitionPath, legalStateTransitionPathBegin, legalStateTransitionPathEnd, getCurrentState, Error)

{-| TODO: Docs

@docs init, Model, subscriptions, eventSubscriptions, addUnsavedChanges, removeUnsavedChanges, Msg, update, updateState, stateChanges, supportsPageTransitionEvents, events, State, stateToString, stateFromString, legalStateTransitions, legalStateTransitionPath, legalStateTransitionPathBegin, legalStateTransitionPathEnd, getCurrentState, Error

-}

import Elm.Kernel.PageLifecycle
import Json.Decode as JsonD
import Set exposing (Set)
import Task exposing (Task)
import WebApi.Browser exposing (document)
import WebApi.JavaScript as JavaScript
import WebApi.Window as Window



--Based on https://github.com/GoogleChromeLabs/page-lifecycle


{-| TODO: docs
-}
init : ( Model, Cmd Msg )
init =
    ( { state = Active
      , unsavedChanges = Set.empty
      }
    , Task.attempt GotNewState getCurrentState
    )



-- MODEL


{-| TODO: docs
-}
type alias Model =
    { state : State
    , unsavedChanges : Set String
    }


{-| TODO: docs
-}
subscriptions : Model -> Sub Msg
subscriptions model =
    [ eventSubscriptions
    , if Set.isEmpty model.unsavedChanges then
        Sub.none

      else
        Window.preventDefaultOn "beforeunload"
            (JsonD.map (\evt -> ( GotBeforeUnload evt, True )) JsonD.value)
    ]
        |> Sub.batch


{-| TODO: docs
-}
eventSubscriptions : Sub Msg
eventSubscriptions =
    List.map
        (\evtType ->
            Window.on evtType (JsonD.map (GotEvent evtType) JsonD.value)
        )
        events
        |> Sub.batch


{-| TODO: docs
-}
addUnsavedChanges : String -> Model -> Model
addUnsavedChanges id model =
    { model | unsavedChanges = Set.insert id model.unsavedChanges }


{-| TODO: docs
-}
removeUnsavedChanges : String -> Model -> Model
removeUnsavedChanges id model =
    { model | unsavedChanges = Set.remove id model.unsavedChanges }



-- UPDATE


{-| TODO: docs
-}
type Msg
    = GotEvent String JsonD.Value
    | GotNewState (Result Error State)
    | GotBeforeUnload JsonD.Value


{-| TODO: docs
-}
update : Msg -> Model -> ( Model, Cmd Msg, Result Error (List ( State, State )) )
update msg model =
    case msg of
        GotEvent evtType evt ->
            let
                maybeNewStateTask =
                    case evtType of
                        "pageshow" ->
                            Just getCurrentState

                        "resume" ->
                            Just getCurrentState

                        "focus" ->
                            Just (Task.succeed Active)

                        "blur" ->
                            -- The `blur` event can fire while the page is being unloaded, so we
                            -- only need to update the state if the current state is "active".
                            if model.state == Active then
                                Just getCurrentState

                            else
                                Nothing

                        "unload" ->
                            pageHideOrUnload ()

                        "pagehide" ->
                            pageHideOrUnload ()

                        "visibilitychange" ->
                            -- The document's `visibilityState` will change to hidden  as the page
                            -- is being unloaded, but in such cases the lifecycle state shouldn't
                            -- change.
                            if model.state /= Frozen && model.state /= Terminated then
                                Just getCurrentState

                            else
                                Nothing

                        "freeze" ->
                            Just (Task.succeed Frozen)

                        _ ->
                            Just (Task.fail (UnknownEventType evtType))

                pageHideOrUnload lazy =
                    case JsonD.decodeValue (JsonD.field "persisted" JsonD.bool) evt of
                        Ok True ->
                            Just (Task.succeed Frozen)

                        Ok False ->
                            Just (Task.succeed Terminated)

                        Err jsonDError ->
                            Just (Task.fail (FailedDecodingPersistedField jsonDError))
            in
            ( model
            , case maybeNewStateTask of
                Nothing ->
                    Cmd.none

                Just stateTask ->
                    Task.attempt GotNewState stateTask
            , Ok []
            )

        GotNewState (Ok newState) ->
            case updateState newState model of
                Ok ( newModel, stateChanges_ ) ->
                    ( newModel, Cmd.none, Ok stateChanges_ )

                Err error ->
                    ( { model | state = newState }, Cmd.none, Err error )

        GotNewState (Err error) ->
            ( model, Cmd.none, Err error )

        GotBeforeUnload evt ->
            ( model, Cmd.none, Ok [] )


{-| TODO: docs
-}
updateState : State -> Model -> Result Error ( Model, List ( State, State ) )
updateState newState model =
    if newState == model.state then
        Ok ( model, [] )

    else
        let
            stateChanges_ =
                stateChanges (legalStateTransitionPath model.state newState) []
        in
        if List.isEmpty stateChanges_ then
            Err (InvalidStateChange model.state newState)

        else
            Ok ( { model | state = newState }, stateChanges_ )


{-| TODO: docs
-}
stateChanges : List State -> List ( State, State ) -> List ( State, State )
stateChanges remainPath acc =
    case remainPath of
        [] ->
            []

        s1 :: [] ->
            []

        s1 :: s2 :: [] ->
            List.reverse (( s1, s2 ) :: acc)

        s1 :: s2 :: tail ->
            stateChanges (s2 :: tail) (( s1, s2 ) :: acc)



-- HELPERS


{-| TODO: docs
-}
supportsPageTransitionEvents : Bool
supportsPageTransitionEvents =
    Elm.Kernel.PageLifecycle.supportsPageTransitionEvents


{-| TODO: docs
-}
events : List String
events =
    [ "focus"
    , "blur"
    , "visibilitychange"
    , "freeze"
    , "resume"
    , "pageshow"

    -- IE9-10 do not support the pagehide event, so we fall back to unload
    -- Note: unload *MUST ONLY* be added conditionally, otherwise it will
    -- prevent page navigation caching (a.k.a bfcache).
    , if supportsPageTransitionEvents then
        "pagehide"

      else
        "unload"
    ]


{-| TODO: docs
-}
type State
    = Active
    | Passive
    | Hidden
    | Frozen
    | Discarded -- Just for completeness, not used
    | Terminated


{-| TODO: docs
-}
stateToString : State -> String
stateToString state =
    case state of
        Active ->
            "active"

        Passive ->
            "passive"

        Hidden ->
            "hidden"

        Frozen ->
            "frozen"

        Discarded ->
            "discarded"

        Terminated ->
            "terminated"


{-| TODO: docs
-}
stateFromString : String -> Maybe State
stateFromString str =
    case str of
        "active" ->
            Just Active

        "passive" ->
            Just Passive

        "hidden" ->
            Just Hidden

        "frozen" ->
            Just Frozen

        "discarded" ->
            Just Discarded

        "terminated" ->
            Just Terminated

        _ ->
            Nothing


{-| TODO: docs
-}
legalStateTransitions : List (List State)
legalStateTransitions =
    -- The normal unload process (bfcache process is addressed above).
    [ [ Active, Passive, Hidden, Terminated ]

    -- An active page transitioning to frozen,
    -- or an unloading page going into the bfcache.
    , [ Active, Passive, Hidden, Frozen ]

    -- A hidden page transitioning back to active.
    , [ Hidden, Passive, Active ]

    -- A frozen page being resumed
    , [ Frozen, Hidden ]

    -- A frozen (bfcached) page navigated back to
    -- Note: [Frozen, Hidden] can happen here, but it's already covered above.
    , [ Frozen, Active ]
    , [ Frozen, Passive ]
    ]



{- Accepts a current state and a future state and returns a list of legal
   state transition paths. This is needed to normalize behavior across
   browsers since some browsers do not fire events in certain cases and thus
   skip states.
-}


{-| TODO: docs
-}
legalStateTransitionPath : State -> State -> List State
legalStateTransitionPath startState endState =
    List.foldl
        (\fullPath wantedPath ->
            if List.isEmpty wantedPath then
                legalStateTransitionPathBegin startState endState fullPath

            else
                wantedPath
        )
        []
        legalStateTransitions


{-| TODO: docs
-}
legalStateTransitionPathBegin : State -> State -> List State -> List State
legalStateTransitionPathBegin startState endState remainPath =
    case remainPath of
        nextState :: tail ->
            if nextState == startState then
                legalStateTransitionPathEnd endState tail [ startState ]

            else
                legalStateTransitionPathBegin startState endState tail

        [] ->
            []


{-| TODO: docs
-}
legalStateTransitionPathEnd : State -> List State -> List State -> List State
legalStateTransitionPathEnd endState remainPath acc =
    case remainPath of
        nextState :: tail ->
            if nextState == endState then
                List.reverse (endState :: acc)

            else
                legalStateTransitionPathEnd endState tail (nextState :: acc)

        [] ->
            []



{-
   Returns the current state based on the document's visibility and
   in input focus states. Note this method is only used to determine
   active vs passive vs hidden states, as other states require listening
   for events.
-}


{-| TODO: docs
-}
getCurrentState : Task Error State
getCurrentState =
    JavaScript.try
        (\() ->
            let
                visibilityState =
                    JavaScript.property document "visibilityState"
                        |> Maybe.andThen
                            (JsonD.decodeValue JsonD.string
                                >> Result.toMaybe
                            )
                        |> Maybe.andThen stateFromString

                hasFocus lazy =
                    JavaScript.callNested document "hasFocus" []
                        |> JsonD.decodeValue JsonD.bool
                        |> Result.withDefault False
            in
            if visibilityState == Just Hidden then
                Hidden

            else if hasFocus () then
                Active

            else
                Passive
        )
        |> Task.mapError (\_ -> ErrorGettingCurrentState)


{-| TODO: docs
-}
type Error
    = UnknownEventType String
    | ErrorGettingCurrentState
    | InvalidStateChange State State
    | FailedDecodingPersistedField JsonD.Error
