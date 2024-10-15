/*

import WebApi.FileSystem as FileSystem exposing (Granted, Denied, Prompt, Abort, NotAllowed, TypeError, TypeMismatch, InvalidModification, NotSupported, QuotaExceeded, NotFound)
import Result exposing (Ok, Err)
import Elm.Kernel.Utils exposing (Tuple0, Tuple2)
import Elm.Kernel.List exposing (fromArray)
import Elm.Kernel.Json exposing (unwrap, wrap)
import Elm.Kernel.Scheduler exposing (binding, succeed, fail)

*/

var _FileSystem_name = function (handle) {
  return handle.name;
};
var _FileSystem_kind = function (handle) {
  return handle.kind;
};

var _FileSystem_queryPermission = F2(function (handle, mode) {
  return __Scheduler_binding(function (callback) {
    handle
      .queryPermission({ mode: mode })
      .then((permission) =>
        callback(__Scheduler_succeed(permissionTag[permission]))
      )
      .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
  });
});

var _FileSystem_requestPermission = F2(function (handle, mode) {
  return __Scheduler_binding(function (callback) {
    handle
      .requestPermission({ mode: mode })
      .then((permission) =>
        callback(__Scheduler_succeed(permissionTag[permission]))
      )
      .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
  });
});

var _FileSystem_getFile = function (fileHandle) {
  return __Scheduler_binding(function (callback) {
    fileHandle
      .getFile()
      .then((file) => callback(__Scheduler_succeed(file)))
      .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
  });
};

var _FileSystem_createWritable = F2(function (keepExistingData, fileHandle) {
  return __Scheduler_binding(function (callback) {
    fileHandle
      .createWritable({ keepExistingData: keepExistingData })
      .then((writable) => callback(__Scheduler_succeed(writable)))
      .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
  });
});

var _FileSystem_write = F2(function (chunk, writable) {
  return __Scheduler_binding(function (callback) {
    writable
      .write(__Json_unwrap(chunk))
      .then(() => callback(__Scheduler_succeed(writable)))
      .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
  });
});

var _FileSystem_seek = F2(function (position, writable) {
  return __Scheduler_binding(function (callback) {
    writable
      .seek(position)
      .then(() => callback(__Scheduler_succeed(writable)))
      .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
  });
});

var _FileSystem_truncate = F2(function (size, writable) {
  return __Scheduler_binding(function (callback) {
    writable
      .truncate(size)
      .then(() => callback(__Scheduler_succeed(writable)))
      .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
  });
});

var _FileSystem_abort = function (writable) {
  return __Scheduler_binding(function (callback) {
    writable
      .abort()
      .then(() => callback(__Scheduler_succeed(writable)))
      .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
  });
};

var _FileSystem_close = function (writable) {
  return __Scheduler_binding(function (callback) {
    writable
      .close()
      .then(() => callback(__Scheduler_succeed(__Utils_Tuple0)))
      .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
  });
};

var _FileSystem_getFileHandle = F3(function (name, create, dirHandle) {
  return __Scheduler_binding(function (callback) {
    dirHandle
      .getFileHandle(name, { create: create })
      .then((fileHandle) => callback(__Scheduler_succeed(fileHandle)))
      .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
  });
});

var _FileSystem_getDirectoryHandle = F3(function (name, create, dirHandle) {
  return __Scheduler_binding(function (callback) {
    dirHandle
      .getDirectoryHandle(name, { create: create })
      .then((dirHandle2) => callback(__Scheduler_succeed(dirHandle2)))
      .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
  });
});

var _FileSystem_resolve = F2(function (fileHandle, dirHandle) {
  return __Scheduler_binding(function (callback) {
    dirHandle
      .resolve(fileHandle)
      .then((path) => callback(__Scheduler_succeed(path)))
      .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
  });
});

var _FileSystem_removeEntry = F3(function (name, recursive, dirHandle) {
  return __Scheduler_binding(function (callback) {
    dirHandle
      .removeEntry(name, { recursive: recursive })
      .then(() => callback(__Scheduler_succeed(__Utils_Tuple0)))
      .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
  });
});

var _FileSystem_showOpenFilePicker = __Scheduler_binding(function (callback) {
  window
    .showOpenFilePicker()
    .then((fileHandles) => callback(__Scheduler_succeed(fileHandles[0])))
    .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
});

var _FileSystem_showOpenFilePickerWithOptions = function (options) {
  return __Scheduler_binding(function (callback) {
    window
      .showOpenFilePicker(__Json_unwrap(options))
      .then((fileHandles) =>
        callback(__Scheduler_succeed(__List_fromArray(fileHandles)))
      )
      .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
  });
};

var _FileSystem_showSaveFilePicker = __Scheduler_binding(function (callback) {
  window
    .showSaveFilePicker()
    .then((fileHandle) => callback(__Scheduler_succeed(fileHandle)))
    .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
});

var _FileSystem_showSaveFilePickerWithOptions = function (options) {
  return __Scheduler_binding(function (callback) {
    window
      .showSaveFilePicker(__Json_unwrap(options))
      .then((fileHandle) => callback(__Scheduler_succeed(fileHandle)))
      .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
  });
};

var _FileSystem_showDirectoryPicker = __Scheduler_binding(function (callback) {
  window
    .showDirectoryPicker()
    .then((dirHandle) => callback(__Scheduler_succeed(dirHandle)))
    .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
});

var _FileSystem_showDirectoryPickerWithOptions = function (options) {
  return __Scheduler_binding(function (callback) {
    window
      .showDirectoryPicker(__Json_unwrap(options))
      .then((dirHandle) => callback(__Scheduler_succeed(dirHandle)))
      .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
  });
};

var _FileSystem_values = function (dirHandle) {
  return __Scheduler_binding(function (callback) {
    dirHandle
      .values()
      .next()
      .then((entry) => callback(__Scheduler_succeed(entry)))
      .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
  });
};

var _FileSystem_values = (dirHandle) => dirHandle.values();

var _FileSystem_next = function (iterator) {
  return __Scheduler_binding(function (callback) {
    iterator
      .next()
      .then((entry) =>
        callback(__Scheduler_succeed(__Utils_Tuple2(entry.done, entry.value)))
      )
      .catch((e) => callback(__Scheduler_fail(errorTag(e.name))));
  });
};

var _FileSystem_bytesToJS = (bytes) => __Json_wrap(bytes);
var _FileSystem_blob = F2((mime, bytes) =>
  __Json_wrap(new Blob([bytes], { type: mime }))
);

var permissionTag = {
  granted: __FileSystem_Granted,
  denied: __FileSystem_Denied,
  prompt: __FileSystem_Prompt,
};

var errorTag = function (name) {
  switch (name) {
    case 'NotAllowedError':
      return __FileSystem_NotAllowed;
    case 'NotFoundError':
      return __FileSystem_NotFound;
    case 'TypeError':
      return __FileSystem_TypeError;
    case 'TypeMismatchError':
      return __FileSystem_TypeMismatch;
    case 'InvalidModificationError':
      return __FileSystem_InvalidModification;
    case 'QuotaExceededError':
      return __FileSystem_QuotaExceeded;
    case 'AbortError':
      return __FileSystem_Abort;
    default:
      return __FileSystem_NotSupported;
  }
};
