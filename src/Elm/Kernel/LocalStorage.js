/*

import WebApi.LocalStorage as LocalStorage exposing (NotSupported, QuotaExceeded, NotFound)
import Result exposing (Ok, Err)
import Elm.Kernel.Utils exposing (Tuple0)
import Elm.Kernel.Scheduler exposing (binding, succeed, fail)

*/

var _LocalStorage_setItem = F2(function (key, val) {
  return __Scheduler_binding(function (callback) {
    try {
      self.localStorage.setItem(key, val);
      callback(__Scheduler_succeed(__Utils_Tuple0));
    } catch (e) {
      const isQuotaExceeded =
        // everything except Firefox
        e.code === 22 ||
        // Firefox
        e.code === 1014 ||
        // test name field too, because code might not be present
        // everything except Firefox
        e.name === 'QuotaExceededError' ||
        // Firefox
        e.name === 'NS_ERROR_DOM_QUOTA_REACHED';
      callback(
        __Scheduler_fail(
          isQuotaExceeded
            ? __LocalStorage_QuotaExceeded
            : __LocalStorage_NotSupported
        )
      );
    }
  });
});

function _LocalStorage_getItem(key) {
  return __Scheduler_binding(function (callback) {
    try {
      const item = self.localStorage.getItem(key);
      if (item) {
        callback(__Scheduler_succeed(item));
      } else {
        callback(__Scheduler_fail(__LocalStorage_NotFound));
      }
    } catch (e) {
      callback(__Scheduler_fail(__LocalStorage_NotSupported));
    }
  });
}

function _LocalStorage_key(index) {
  return __Scheduler_binding(function (callback) {
    try {
      const key = self.localStorage.key(index);
      if (key) {
        callback(__Scheduler_succeed(key));
      } else {
        callback(__Scheduler_fail(__LocalStorage_NotFound));
      }
    } catch (e) {
      callback(__Scheduler_fail(__LocalStorage_NotSupported));
    }
  });
}

function _LocalStorage_removeItem(key) {
  return __Scheduler_binding(function (callback) {
    try {
      self.localStorage.removeItem(key);
      callback(__Scheduler_succeed(__Utils_Tuple0));
    } catch (e) {
      callback(__Scheduler_fail(__LocalStorage_NotSupported));
    }
  });
}

var _LocalStorage_length = __Scheduler_binding(function (callback) {
  try {
    callback(__Scheduler_succeed(self.localStorage.length));
  } catch (e) {
    callback(__Scheduler_succeed(0));
  }
});

var _LocalStorage_clear = __Scheduler_binding(function (callback) {
  try {
    self.localStorage.clear();
    callback(__Scheduler_succeed(__Utils_Tuple0));
  } catch (e) {
    callback(__Scheduler_fail(__LocalStorage_NotSupported));
  }
});
