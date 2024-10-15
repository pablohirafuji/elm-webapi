module WebApi.FileSystem exposing (DirectoryHandle, DirectoryPickerOptions, Error(..), FileHandle, FilePickerAccept, Handle(..), OpenFilePickerOptions, PermissionMode(..), PermissionState(..), SaveFilePickerOptions, StartInDirectory(..), WritableFileStream, WriteChunk(..), WriteCommand(..), WriteParams, WriteParamsData(..), abort, close, createWritable, errorToString, getDirectoryHandle, getFile, getFileHandle, name, permissionModeToString, queryPermission, removeEntry, requestPermission, resolve, seek, showDirectoryPicker, showDirectoryPickerWithOptions, showOpenFilePicker, showOpenFilePickerWithOptions, showSaveFilePicker, showSaveFilePickerWithOptions, truncate, values, write)

{-| TODO: Docs

@docs DirectoryHandle, DirectoryPickerOptions, Error, FileHandle, FilePickerAccept, Handle, OpenFilePickerOptions, PermissionMode, PermissionState, SaveFilePickerOptions, StartInDirectory, WritableFileStream, WriteChunk, WriteCommand, WriteParams, WriteParamsData, abort, close, createWritable, errorToString, getDirectoryHandle, getFile, getFileHandle, name, permissionModeToString, queryPermission, removeEntry, requestPermission, resolve, seek, showDirectoryPicker, showDirectoryPickerWithOptions, showOpenFilePicker, showOpenFilePickerWithOptions, showSaveFilePicker, showSaveFilePickerWithOptions, truncate, values, write

-}

import Bytes exposing (Bytes)
import Elm.Kernel.FileSystem
import File
import Json.Encode as JsonE
import Task exposing (Task)


{-| TODO: docs
-}
type Handle
    = Directory DirectoryHandle
    | File FileHandle


{-| TODO: docs
-}
type DirectoryHandle
    = DirectoryHandle JsonE.Value


{-| TODO: docs
-}
type FileHandle
    = FileHandle JsonE.Value


{-| TODO: docs
-}
type PermissionState
    = Granted
    | Denied
    | Prompt


{-| TODO: docs
-}
type PermissionMode
    = Read
    | ReadWrite


{-| TODO: docs
-}
permissionModeToString : PermissionMode -> String
permissionModeToString mode =
    case mode of
        Read ->
            "read"

        ReadWrite ->
            "readwrite"


{-| TODO: docs
-}
type WritableFileStream
    = WritableFileStream


{-| TODO: docs
-}
type DirectoryIterator
    = DirectoryIterator


{-| TODO: docs
-}
name : Handle -> String
name handle =
    Elm.Kernel.FileSystem.name (extractHandleJsonValue handle)


{-| TODO: docs
-}
queryPermission : Handle -> PermissionMode -> Task Error PermissionState
queryPermission handle mode =
    Elm.Kernel.FileSystem.queryPermission (extractHandleJsonValue handle) (permissionModeToString mode)


{-| TODO: docs
-}
requestPermission : Handle -> PermissionMode -> Task Error PermissionState
requestPermission handle mode =
    Elm.Kernel.FileSystem.requestPermission (extractHandleJsonValue handle) (permissionModeToString mode)


{-| TODO: docs
-}
extractHandleJsonValue : Handle -> JsonE.Value
extractHandleJsonValue handle =
    case handle of
        File (FileHandle fileHandle) ->
            fileHandle

        Directory (DirectoryHandle dirHandle) ->
            dirHandle


{-| TODO: docs
-}
getFile : FileHandle -> Task Error File.File
getFile (FileHandle fileHandle) =
    Elm.Kernel.FileSystem.getFile fileHandle


{-| TODO: docs
-}
createWritable : Bool -> FileHandle -> Task Error WritableFileStream
createWritable keepExistingData (FileHandle fileHandle) =
    Elm.Kernel.FileSystem.createWritable keepExistingData fileHandle


{-| TODO: docs
-}
write : WriteChunk -> WritableFileStream -> Task Error WritableFileStream
write chunk writable =
    Elm.Kernel.FileSystem.write (writeChunkToJsonValue chunk) writable


{-| TODO: docs
-}
seek : Int -> WritableFileStream -> Task Error WritableFileStream
seek =
    Elm.Kernel.FileSystem.seek


{-| TODO: docs
-}
truncate : Int -> WritableFileStream -> Task Error WritableFileStream
truncate =
    Elm.Kernel.FileSystem.truncate


{-| TODO: docs
-}
abort : WritableFileStream -> Task Error WritableFileStream
abort =
    Elm.Kernel.FileSystem.abort


{-| TODO: docs
-}
close : WritableFileStream -> Task Error ()
close =
    Elm.Kernel.FileSystem.close


{-| TODO: docs
-}
getFileHandle : String -> Bool -> DirectoryHandle -> Task Error FileHandle
getFileHandle name_ create (DirectoryHandle dirHandle) =
    Elm.Kernel.FileSystem.getFileHandle name_ create dirHandle
        |> Task.map FileHandle


{-| TODO: docs
-}
getDirectoryHandle : String -> Bool -> DirectoryHandle -> Task Error DirectoryHandle
getDirectoryHandle name_ create (DirectoryHandle dirHandle) =
    Elm.Kernel.FileSystem.getDirectoryHandle name_ create dirHandle
        |> Task.map DirectoryHandle


{-| TODO: docs
-}
resolve : FileHandle -> DirectoryHandle -> Task Error (List String)
resolve (FileHandle fileHandle) (DirectoryHandle dirHandle) =
    Elm.Kernel.FileSystem.resolve fileHandle dirHandle


{-| TODO: docs
-}
removeEntry : String -> Bool -> DirectoryHandle -> Task Error ()
removeEntry name_ recursive (DirectoryHandle dirHandle) =
    Elm.Kernel.FileSystem.removeEntry name_ recursive dirHandle


{-| TODO: docs
-}
showOpenFilePicker : Task Error FileHandle
showOpenFilePicker =
    Elm.Kernel.FileSystem.showOpenFilePicker
        |> Task.map FileHandle


{-| TODO: docs
-}
showOpenFilePickerWithOptions : OpenFilePickerOptions -> Task Error (List FileHandle)
showOpenFilePickerWithOptions options =
    Elm.Kernel.FileSystem.showOpenFilePickerWithOptions (openFilePickerOptionsToJsonValue options)
        |> Task.map (List.map FileHandle)


{-| TODO: docs
-}
showSaveFilePicker : Task Error FileHandle
showSaveFilePicker =
    Elm.Kernel.FileSystem.showSaveFilePicker
        |> Task.map FileHandle


{-| TODO: docs
-}
showSaveFilePickerWithOptions : SaveFilePickerOptions -> Task Error FileHandle
showSaveFilePickerWithOptions options =
    Elm.Kernel.FileSystem.showSaveFilePickerWithOptions (saveFilePickerOptionsToJsonValue options)
        |> Task.map FileHandle


{-| TODO: docs
-}
showDirectoryPicker : Task Error DirectoryHandle
showDirectoryPicker =
    Elm.Kernel.FileSystem.showDirectoryPicker
        |> Task.map DirectoryHandle


{-| TODO: docs
-}
showDirectoryPickerWithOptions : DirectoryPickerOptions -> Task Error DirectoryHandle
showDirectoryPickerWithOptions options =
    Elm.Kernel.FileSystem.showDirectoryPickerWithOptions (directoryPickerOptionsToJsonValue options)
        |> Task.map DirectoryHandle


{-| TODO: docs
-}
values : (Handle -> a -> a) -> a -> DirectoryHandle -> Task Error a
values fn a (DirectoryHandle dirHandle) =
    values_ fn a (Elm.Kernel.FileSystem.values dirHandle)


values_ : (Handle -> a -> a) -> a -> DirectoryIterator -> Task Error a
values_ fn a it =
    iteratorNext it
        |> Task.andThen
            (\maybeHandle ->
                case maybeHandle of
                    Nothing ->
                        Task.succeed a

                    Just handle ->
                        values_ fn (fn handle a) it
            )


{-| TODO: docs
-}
iteratorNext : DirectoryIterator -> Task Error (Maybe Handle)
iteratorNext iterator =
    Elm.Kernel.FileSystem.next iterator
        |> Task.map
            (\( isDone, val ) ->
                if isDone then
                    Nothing

                else if Elm.Kernel.FileSystem.kind val == "file" then
                    Just (File (FileHandle val))

                else
                    Just (Directory (DirectoryHandle val))
            )


{-| TODO: docs
-}
type alias OpenFilePickerOptions =
    { types : List FilePickerAccept
    , excludeAcceptAllOption : Maybe Bool
    , id : Maybe String
    , startIn : Maybe StartInDirectory
    , multiple : Maybe Bool
    }


{-| TODO: docs
-}
type alias SaveFilePickerOptions =
    { types : List FilePickerAccept
    , excludeAcceptAllOption : Maybe Bool
    , id : Maybe String
    , startIn : Maybe StartInDirectory
    , suggestedName : Maybe String
    }


{-| TODO: docs
-}
type alias DirectoryPickerOptions =
    { id : Maybe String
    , startIn : Maybe StartInDirectory
    }


{-| TODO: docs
-}
type alias FilePickerAccept =
    { description : String
    , accept : List ( String, List String )
    }


{-| TODO: docs
-}
type StartInDirectory
    = WellKnownDirectory String
    | StartInFileHandle FileHandle
    | StartInDirectoryHandle DirectoryHandle


{-| TODO: docs
-}
type WriteChunk
    = BytesChunk Bytes -- BufferSource in javascript
    | BlobChunk String Bytes
    | StringChunk String
    | WriteParamsChunk WriteParams


{-| TODO: docs
-}
type alias WriteParams =
    { type_ : WriteCommand
    , size : Maybe Int
    , position : Maybe Int
    , data : Maybe WriteParamsData
    }


{-| TODO: docs
-}
type WriteParamsData
    = BytesData Bytes -- BufferSource in javascript
    | BlobData String Bytes
    | StringData String


{-| TODO: docs
-}
type WriteCommand
    = Write
    | Seek
    | Truncate


{-| TODO: docs
-}
type Error
    = NotFound
    | NotSupported
    | QuotaExceeded
    | NotAllowed
    | Abort
    | TypeError
    | TypeMismatch
    | InvalidModification


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

        NotAllowed ->
            "NotAllowed"

        Abort ->
            "Abort"

        TypeError ->
            "TypeError"

        TypeMismatch ->
            "TypeMismatch"

        InvalidModification ->
            "InvalidModification"


{-| TODO: docs
-}
openFilePickerOptionsToJsonValue : OpenFilePickerOptions -> JsonE.Value
openFilePickerOptionsToJsonValue opts =
    [ typesToJsonEntry opts.types
    , Maybe.map excludeAcceptAllOptionToJsonEntry opts.excludeAcceptAllOption
    , Maybe.map idToJsonEntry opts.id
    , Maybe.map startInToJsonEntry opts.startIn
    , Maybe.map (\b -> ( "multiple", JsonE.bool b )) opts.multiple
    ]
        |> List.filterMap identity
        |> JsonE.object


{-| TODO: docs
-}
saveFilePickerOptionsToJsonValue : SaveFilePickerOptions -> JsonE.Value
saveFilePickerOptionsToJsonValue opts =
    [ typesToJsonEntry opts.types
    , Maybe.map excludeAcceptAllOptionToJsonEntry opts.excludeAcceptAllOption
    , Maybe.map idToJsonEntry opts.id
    , Maybe.map startInToJsonEntry opts.startIn
    , Maybe.map (\str -> ( "suggestedName", JsonE.string str )) opts.suggestedName
    ]
        |> List.filterMap identity
        |> JsonE.object


{-| TODO: docs
-}
directoryPickerOptionsToJsonValue : DirectoryPickerOptions -> JsonE.Value
directoryPickerOptionsToJsonValue opts =
    [ Maybe.map idToJsonEntry opts.id
    , Maybe.map startInToJsonEntry opts.startIn
    ]
        |> List.filterMap identity
        |> JsonE.object


{-| TODO: docs
-}
filePickerAcceptToJsonValue : FilePickerAccept -> JsonE.Value
filePickerAcceptToJsonValue opts =
    [ ( "description", JsonE.string opts.description )
    , ( "accept"
      , List.map (Tuple.mapSecond (JsonE.list JsonE.string)) opts.accept
            |> JsonE.object
      )
    ]
        |> JsonE.object


{-| TODO: docs
-}
typesToJsonEntry : List FilePickerAccept -> Maybe ( String, JsonE.Value )
typesToJsonEntry accepts =
    if List.isEmpty accepts then
        Nothing

    else
        Just ( "types", JsonE.list filePickerAcceptToJsonValue accepts )


{-| TODO: docs
-}
excludeAcceptAllOptionToJsonEntry : Bool -> ( String, JsonE.Value )
excludeAcceptAllOptionToJsonEntry b =
    ( "excludeAcceptAllOption", JsonE.bool b )


{-| TODO: docs
-}
idToJsonEntry : String -> ( String, JsonE.Value )
idToJsonEntry str =
    ( "id", JsonE.string str )


{-| TODO: docs
-}
startInToJsonEntry : StartInDirectory -> ( String, JsonE.Value )
startInToJsonEntry startIn =
    ( "startIn"
    , case startIn of
        WellKnownDirectory dir ->
            JsonE.string dir

        StartInFileHandle (FileHandle fileHandle) ->
            fileHandle

        StartInDirectoryHandle (DirectoryHandle dirHandle) ->
            dirHandle
    )


{-| TODO: docs
-}
writeCommandToString : WriteCommand -> String
writeCommandToString wc =
    case wc of
        Write ->
            "write"

        Seek ->
            "seek"

        Truncate ->
            "truncate"


{-| TODO: docs
-}
writeChunkToJsonValue : WriteChunk -> JsonE.Value
writeChunkToJsonValue chunk =
    case chunk of
        BytesChunk bytes ->
            Elm.Kernel.FileSystem.bytesToJS bytes

        BlobChunk mime bytes ->
            Elm.Kernel.FileSystem.blob mime bytes

        StringChunk str ->
            JsonE.string str

        WriteParamsChunk params ->
            [ Just ( "type", JsonE.string (writeCommandToString params.type_) )
            , Maybe.map (JsonE.int >> Tuple.pair "size") params.size
            , Maybe.map (JsonE.int >> Tuple.pair "position") params.position
            , Maybe.map
                (writeParamsDataToJsonValue >> Tuple.pair "data")
                params.data
            ]
                |> List.filterMap identity
                |> JsonE.object


{-| TODO: docs
-}
writeParamsDataToJsonValue : WriteParamsData -> JsonE.Value
writeParamsDataToJsonValue data =
    case data of
        BytesData bytes ->
            Elm.Kernel.FileSystem.bytesToJS bytes

        BlobData mime bytes ->
            Elm.Kernel.FileSystem.blob mime bytes

        StringData str ->
            JsonE.string str
