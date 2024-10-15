/*
import Elm.Kernel.Scheduler exposing (binding, fail, rawSpawn, succeed, spawn)
import Maybe exposing (Just, Nothing)
import Elm.Kernel.Utils exposing (Tuple0, Tuple2)
import Elm.Kernel.Json exposing (runHelp, unwrap, wrap)
import WebApi.JavaScript as JavaScript exposing (toHandlerInt)
import Elm.Kernel.VirtualDom exposing (appendChild, applyPatches, diff, doc, node, passiveSupported, render, divertHrefToApp)
import Result exposing (isOk)

*/

var _JavaScript_bytesDecoder = function (val) {
  return __Json_unwrap(val);
};

var _JavaScript_bytesToJson = function (val) {
  return __Json_wrap(val);
};

var _JavaScript_globalThis = __Json_wrap(globalThis);

var _JavaScript_call = F2(function (fn, args) {
  return __Json_wrap(__Json_unwrap(fn).apply(null, __Json_unwrap(args)));
});

var _JavaScript_callNested = F3(function (wrappedObj, at, args) {
  var obj = __Json_unwrap(wrappedObj);
  return __Json_wrap(obj[at].apply(obj, __Json_unwrap(args)));
});

var _JavaScript_callNested2 = F4(function (wrappedObj, at1, at2, args) {
  var obj = __Json_unwrap(wrappedObj);
  return __Json_wrap(obj[at1][at2].apply(obj[at1], __Json_unwrap(args)));
});

var _JavaScript_callNested3 = F5(function (wrappedObj, at1, at2, at3, args) {
  var obj = __Json_unwrap(wrappedObj);
  return __Json_wrap(
    obj[at1][at2][at3].apply(obj[at1][at2], __Json_unwrap(args))
  );
});

var _JavaScript_access = F2(function (wrappedObj, wrappedAt) {
  var obj = __Json_unwrap(wrappedObj);
  var at = __Json_unwrap(wrappedAt);
  var objAt = [obj].concat(at).reduce((a, b) => { return a[b] });
  return __Json_wrap(objAt);
});

var _JavaScript_newCall = F2(function (wrappedObj, wrappedArgs) {
  var obj = __Json_unwrap(wrappedObj);
  var args = [obj].concat(__Json_unwrap(wrappedArgs));
  var n = new (Function.prototype.bind.apply(obj, args));
  return __Json_wrap(n);
});

var _JavaScript_functionArg = function (fn) {
  return __Json_wrap(function () {
    return fn(__Json_wrap(arguments));
  });
};

var _JavaScript_property = F2(function (wrappedObj, name) {
  var obj = __Json_unwrap(wrappedObj);
  if (obj && obj[name] !== undefined)
    return __Maybe_Just(__Json_wrap(obj[name]));
  return __Maybe_Nothing;
});

var _JavaScript_promise = function (promise) {
  return __Scheduler_binding(function (callback) {
    __Json_unwrap(promise)
      .then(function () {
        callback(__Scheduler_succeed(__Json_wrap(arguments)));
      })
      .catch(function () {
        callback(__Scheduler_fail(__Json_wrap(arguments)));
      });
  });
};

var _JavaScript_try = function (toTry) {
  return __Scheduler_binding(function (callback) {
    try {
      callback(__Scheduler_succeed(toTry(__Utils_Tuple0)));
    } catch (e) {
      callback(__Scheduler_fail(__Json_wrap(e)));
    }
  });
};

var _JavaScript_isNull = function (any) {
  return __Json_unwrap(any) === null;
};

var _JavaScript_typeof = function (any) {
  return typeof __Json_unwrap(any);
};

const _JavaScript_addEventListener = F4(function (target, eventName, handler, sendToSelf) {
  let target_ = __Json_unwrap(target);
  return __Scheduler_spawn(
    __Scheduler_binding(function (callback) {
      function handler_(event) {
        var result = __Json_runHelp(handler.a, event);

        if (!__Result_isOk(result)) {
          return __Scheduler_rawSpawn(sendToSelf(__Maybe_Nothing));
        }

        var tag = __JavaScript_toHandlerInt(handler);

        // 0 = Normal
        // 1 = MayStopPropagation
        // 2 = MayPreventDefault
        // 3 = Custom

        var value = result.a;
        var message = !tag ? value : tag < 3 ? value.a : value.__$message;
        var stopPropagation =
          tag == 1 ? value.b : tag == 3 && value.__$stopPropagation;
        var preventDefault =
          tag == 2 ? value.b : tag == 3 && value.__$preventDefault;

        if (stopPropagation) event.stopPropagation();
        if (preventDefault) event.preventDefault();

        __Scheduler_rawSpawn(sendToSelf(__Maybe_Just(message)));
      }
      target_.addEventListener(
        eventName,
        handler_,
        __VirtualDom_passiveSupported && {
          passive: __JavaScript_toHandlerInt(handler) < 2,
        }
      );
      return function () {
        target_.removeEventListener(eventName, handler_);
      };
    })
  );
});
