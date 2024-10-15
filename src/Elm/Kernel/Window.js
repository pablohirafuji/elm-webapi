/*
import Elm.Kernel.Scheduler exposing (binding, fail, rawSpawn, succeed, spawn)
import Elm.Kernel.Json exposing (runHelp)
import Elm.Kernel.Utils exposing (Tuple0, Tuple2)
import Elm.Kernel.VirtualDom exposing (appendChild, applyPatches, diff, doc, node, passiveSupported, render, divertHrefToApp)
import Maybe exposing (Just, Nothing)
import Result exposing (isOk)
import WebApi.Window as Window exposing (toHandlerInt)
*/

// From https://github.com/elm/browser/blob/1.0.2/src/Elm/Kernel/Browser.js#L99
var _Window_cancelAnimationFrame =
  typeof cancelAnimationFrame !== 'undefined'
    ? cancelAnimationFrame
    : function (id) {
        clearTimeout(id);
      };

var _Window_requestAnimationFrame_ =
  typeof requestAnimationFrame !== 'undefined'
    ? requestAnimationFrame
    : function (callback) {
        return setTimeout(callback, 1000 / 60);
      };

var _Window_requestAnimationFrame = function (r) {
  return __Scheduler_binding(function (callback) {
    var id = _Window_requestAnimationFrame_(function () {
      callback(__Scheduler_succeed(r));
    });

    return function () {
      _Window_cancelAnimationFrame(id);
    };
  });
};

var _Window_fakeNode = {
  addEventListener: function () {},
  removeEventListener: function () {},
};
var _Window_window = typeof window !== 'undefined' ? window : _Window_fakeNode;

var _Window_on = F3(function (eventName, handler, sendToSelf) {
  return __Scheduler_spawn(
    __Scheduler_binding(function (callback) {
      function handler_(event) {
        var result = __Json_runHelp(handler.a, event);

        if (!__Result_isOk(result)) {
          return __Scheduler_rawSpawn(sendToSelf(__Maybe_Nothing));
        }

        var tag = __Window_toHandlerInt(handler);

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
      _Window_window.addEventListener(
        eventName,
        handler_,
        __VirtualDom_passiveSupported && {
          passive: __Window_toHandlerInt(handler) < 2,
        }
      );
      return function () {
        _Window_window.removeEventListener(eventName, handler_);
      };
    })
  );
});
