module Main exposing (main)

import Browser
import Bytes exposing (Bytes)
import Dict exposing (Dict)
import File exposing (File)
import Hex.Convert
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy as Html
import Image
import Json.Decode as JsonD
import QRCode
import Task
import Time exposing (Posix)
import WebApi.Crypto as Crypto
import WebApi.FileSystem as FileSystem
import WebApi.LocalStorage as LocalStorage
import WebApi.Window as Window


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( initialModel, getEntries )
        , view = view
        , update = update
        , subscriptions =
            \_ ->
                Window.on "blur" (JsonD.succeed OnWindowBlur)
        }


type alias Model =
    { entries : Result LocalStorage.Error (Dict String String)
    , taskResult : Maybe (Result LocalStorage.Error ())
    , getItem : Maybe (Result LocalStorage.Error String)
    , key : String
    , value : String
    , length : Maybe Int
    , randomBytesLength : String
    , randomBytes : Maybe (Result Crypto.Error Bytes)
    , randomUUID : Maybe (Result Crypto.Error String)
    , directoryValues : List FileSystem.Handle
    , qrCodeMsg : String
    , requestAnimationFrame : Maybe ( Posix, Posix )
    }


initialModel : Model
initialModel =
    { entries = Ok Dict.empty
    , taskResult = Nothing
    , getItem = Nothing
    , key = "key"
    , value = "value"
    , length = Nothing
    , randomBytesLength = "12"
    , randomBytes = Nothing
    , randomUUID = Nothing
    , directoryValues = []
    , qrCodeMsg = "KernelCode"
    , requestAnimationFrame = Nothing
    }


type Msg
    = GotEntries (Result LocalStorage.Error (Dict String String))
    | EnteredKey String
    | EnteredValue String
    | GetItem
    | GotItem (Result LocalStorage.Error String)
    | SetItem
    | SettedItem (Result LocalStorage.Error ())
    | RemoveItem
    | Clear
    | GetLength
    | GotLength Int
    | EnteredBytesLenght String
    | GetRandomBytes
    | GotRandomBytes (Result Crypto.Error Bytes)
    | GetRandomUUID
    | GotRandomUUID (Result Crypto.Error String)
    | ShowOpenFilePicker
    | GotOpenFilePicker (Result FileSystem.Error (List String))
    | ShowDirectoryPicker
    | GotDirectoryPicker (Result FileSystem.Error FileSystem.DirectoryHandle)
    | GotDirectoryValues (Result FileSystem.Error (List FileSystem.Handle))
    | SaveFilePicker
    | GotSaveFilePicker (Result FileSystem.Error ())
    | EnteredQRCodeMsg String
    | SaveQRCode
    | RequestAnimationFrame
    | GotAnimationFrame ( Posix, Posix )
    | OnWindowBlur


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotEntries res ->
            ( { model | entries = res }, Cmd.none )

        EnteredKey str ->
            ( { model | key = str }, Cmd.none )

        EnteredValue str ->
            ( { model | value = str }, Cmd.none )

        GetItem ->
            ( model
            , LocalStorage.getItem model.key
                |> Task.attempt GotItem
            )

        GotItem res ->
            ( { model | getItem = Just res }, getEntries )

        SetItem ->
            ( model
            , LocalStorage.setItem model.key model.value
                |> Task.attempt SettedItem
            )

        SettedItem res ->
            ( { model | taskResult = Just res }, getEntries )

        RemoveItem ->
            ( model
            , LocalStorage.removeItem model.key
                |> Task.attempt SettedItem
            )

        Clear ->
            ( model
            , LocalStorage.clear
                |> Task.attempt SettedItem
            )

        GetLength ->
            ( model
            , LocalStorage.length
                |> Task.perform GotLength
            )

        GotLength length ->
            ( { model | length = Just length }, Cmd.none )

        EnteredBytesLenght str ->
            ( { model | randomBytesLength = str }, Cmd.none )

        GetRandomBytes ->
            ( model
            , String.toInt model.randomBytesLength
                |> Maybe.withDefault 0
                |> Crypto.getRandomBytes
                |> Task.attempt GotRandomBytes
            )

        GotRandomBytes res ->
            ( { model | randomBytes = Just res }, Cmd.none )

        GetRandomUUID ->
            ( model
            , Crypto.randomUUID
                |> Task.attempt GotRandomUUID
            )

        GotRandomUUID res ->
            ( { model | randomUUID = Just res }, Cmd.none )

        ShowOpenFilePicker ->
            ( model
            , FileSystem.showOpenFilePickerWithOptions
                { types =
                    [ { description = "Text file"
                      , accept = [ ( "text/*", [ ".csv", ".txt" ] ) ]
                      }
                    ]
                , excludeAcceptAllOption = Just False
                , id = Nothing
                , startIn = Nothing
                , multiple = Just True
                }
                |> Task.andThen (List.map FileSystem.getFile >> Task.sequence)
                |> Task.andThen (List.map File.toString >> Task.sequence)
                |> Task.attempt GotOpenFilePicker
            )

        GotOpenFilePicker (Err err) ->
            let
                x =
                    Debug.log "err" err
            in
            ( model, Cmd.none )

        GotOpenFilePicker (Ok fileHandles) ->
            let
                x =
                    Debug.log "ok" fileHandles
            in
            ( model, Cmd.none )

        ShowDirectoryPicker ->
            ( model
            , FileSystem.showDirectoryPicker
                |> Task.attempt GotDirectoryPicker
            )

        GotDirectoryPicker (Err err) ->
            let
                x =
                    Debug.log "err" err
            in
            ( model, Cmd.none )

        GotDirectoryPicker (Ok dirHandle) ->
            let
                x =
                    Debug.log "ok" (FileSystem.name (FileSystem.Directory dirHandle))
            in
            ( model
            , FileSystem.values (\handle hs -> handle :: hs) [] dirHandle
                |> Task.attempt GotDirectoryValues
            )

        GotDirectoryValues (Err err) ->
            let
                x =
                    Debug.log "err" err
            in
            ( model, Cmd.none )

        GotDirectoryValues (Ok handles) ->
            ( { model | directoryValues = List.reverse handles }, Cmd.none )

        SaveFilePicker ->
            ( model
            , FileSystem.showSaveFilePicker
                |> Task.andThen (FileSystem.createWritable False)
                |> Task.andThen (FileSystem.write (FileSystem.StringChunk "teste"))
                |> Task.andThen FileSystem.close
                |> Task.attempt GotSaveFilePicker
            )

        GotSaveFilePicker _ ->
            ( model, Cmd.none )

        EnteredQRCodeMsg str ->
            ( { model | qrCodeMsg = str }, Cmd.none )

        SaveQRCode ->
            let
                qrCodeBytes =
                    QRCode.fromString model.qrCodeMsg
                        |> Result.map
                            (QRCode.toImage >> Image.toPng)
                        |> Result.withDefault (Image.fromList 4 [ 1, 3, 2 ] |> Image.toPng)
            in
            ( model
            , FileSystem.showSaveFilePickerWithOptions
                { types =
                    [ { description = "Image"
                      , accept = [ ( "image/png", [ ".png" ] ) ]
                      }
                    ]
                , excludeAcceptAllOption = Just True
                , id = Nothing
                , startIn = Nothing
                , suggestedName = Just "image.png"
                }
                |> Task.andThen (FileSystem.createWritable False)
                |> Task.andThen
                    (FileSystem.write (FileSystem.BytesChunk qrCodeBytes))
                |> Task.andThen FileSystem.close
                |> Task.attempt GotSaveFilePicker
            )

        RequestAnimationFrame ->
            ( model
              --, Task.map3 (\start _ end -> ( start, end ))
              --    Time.now
              --    Window.requestAnimationFrame
              --    Time.now
              --|> Task.andThen
              --    (\start ->
              --        Time.now |> Task.map (Tuple.pair start)
              --    )
            , Time.now
                |> Task.andThen Window.requestAnimationFrame
                |> Task.andThen
                    (\start ->
                        Time.now |> Task.map (Tuple.pair start)
                    )
                |> Task.perform GotAnimationFrame
            )

        GotAnimationFrame res ->
            ( { model | requestAnimationFrame = Just res }, Cmd.none )

        OnWindowBlur ->
            let
                x =
                    Debug.log "blur" "blur"
            in
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Demo" ]
        , h2 [] [ text "LocalStorage" ]
        , input [ onInput EnteredKey, value model.key ] []
        , button [ onClick GetItem ] [ text "Get item" ]
        , button [ onClick RemoveItem ] [ text "Remove item" ]
        , br [] []
        , input [ onInput EnteredValue, value model.value ] []
        , button [ onClick SetItem ] [ text "Set item" ]
        , button [ onClick Clear ] [ text "Clear" ]
        , div []
            [ case model.getItem of
                Nothing ->
                    text ""

                Just (Err err) ->
                    p [] [ text ("Get value: Err " ++ errorToString err) ]

                Just (Ok str) ->
                    p [] [ text ("Get value: " ++ str) ]
            ]
        , div []
            [ case model.taskResult of
                Nothing ->
                    text ""

                Just (Err err) ->
                    p [] [ text ("Local Storage Task Result: Err " ++ errorToString err) ]

                Just (Ok ()) ->
                    text ""
            ]
        , div []
            [ button [ onClick GetLength ] [ text "Get Length" ]
            , text " "
            , case model.length of
                Nothing ->
                    text ""

                Just int ->
                    text ("Length: " ++ String.fromInt int)
            ]
        , case model.entries of
            Err err ->
                text (errorToString err)

            Ok entries ->
                table []
                    (tr [] [ th [] [ text "Key" ], th [] [ text "Value" ] ]
                        :: (Dict.toList entries
                                |> List.map
                                    (\( key, val ) ->
                                        tr [] [ td [] [ text key ], td [] [ text val ] ]
                                    )
                           )
                    )
        , h2 [] [ text "Crypto" ]
        , div []
            [ input
                [ onInput EnteredBytesLenght
                , type_ "number"
                , value model.randomBytesLength
                ]
                []
            , button [ onClick GetRandomBytes ] [ text "Get Random Bytes" ]
            , text " "
            , case model.randomBytes of
                Nothing ->
                    text ""

                Just (Err err) ->
                    text ("Err " ++ cryptoErrorToString err)

                Just (Ok bytes) ->
                    text (Hex.Convert.toString bytes)
            ]
        , div []
            [ button [ onClick GetRandomUUID ] [ text "Get Random UUID" ]
            , text " "
            , case model.randomUUID of
                Nothing ->
                    text ""

                Just (Err err) ->
                    text ("Err " ++ cryptoErrorToString err)

                Just (Ok uuid) ->
                    text uuid
            ]
        , h2 [] [ text "FileSystem" ]
        , div []
            [ button [ onClick ShowOpenFilePicker ] [ text "showOpenFilePicker" ]
            , button [ onClick ShowDirectoryPicker ] [ text "showDirectoryPicker" ]
            , button [ onClick SaveFilePicker ] [ text "saveFilePicker" ]
            , ul []
                (List.map
                    (\handle ->
                        li [] [ text (FileSystem.name handle) ]
                    )
                    model.directoryValues
                )
            , br [] []
            , input
                [ onInput EnteredQRCodeMsg
                , value model.qrCodeMsg
                ]
                []
            , Html.lazy viewQRCode model.qrCodeMsg
            , button [ onClick SaveQRCode ] [ text "Save QRCode" ]
            ]
        , h2 [] [ text "Window" ]
        , div []
            [ button [ onClick RequestAnimationFrame ] [ text "Test requestAnimationFrame" ]
            , case model.requestAnimationFrame of
                Nothing ->
                    text ""

                Just ( start, end ) ->
                    [ [ Time.posixToMillis start |> String.fromInt
                      , Time.posixToMillis end |> String.fromInt
                      ]
                        |> String.join ","
                    , String.fromInt (Time.posixToMillis end - Time.posixToMillis start)
                    ]
                        |> String.join ": "
                        |> text
            ]
        ]


errorToString : LocalStorage.Error -> String
errorToString err =
    case err of
        LocalStorage.NotFound ->
            "NotFound"

        LocalStorage.NotSupported ->
            "NotSupported"

        LocalStorage.QuotaExceeded ->
            "QuotaExceeded"


cryptoErrorToString : Crypto.Error -> String
cryptoErrorToString err =
    case err of
        Crypto.NotSupported ->
            "NotSupported"

        Crypto.QuotaExceeded ->
            "QuotaExceeded"


getEntries : Cmd Msg
getEntries =
    LocalStorage.entries |> Task.attempt GotEntries


viewQRCode : String -> Html msg
viewQRCode message =
    QRCode.fromString message
        |> Result.map
            (\qrCode ->
                Html.img
                    [ QRCode.toImage qrCode
                        |> Image.toPngUrl
                        |> src
                    ]
                    []
            )
        |> Result.withDefault
            (Html.text "Error while encoding to QRCode.")
