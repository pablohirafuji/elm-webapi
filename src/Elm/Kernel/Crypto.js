/*

import WebApi.Crypto as Crypto exposing (NotSupported, QuotaExceeded)
import Elm.Kernel.Scheduler exposing (binding, succeed, fail)

*/

function _Crypto_getRandomBytes(lenght) {
  return __Scheduler_binding(function (callback) {
    try {
      let buffer = new ArrayBuffer(lenght);
      let b8 = new Uint8Array(buffer);
      self.crypto.getRandomValues(b8);
      callback(__Scheduler_succeed(new DataView(buffer)));
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
          isQuotaExceeded ? __Crypto_QuotaExceeded : __Crypto_NotSupported
        )
      );
    }
  });
}

var _Crypto_randomUUID = __Scheduler_binding(function (callback) {
  try {
    callback(__Scheduler_succeed(self.crypto.randomUUID()));
  } catch (e) {
    callback(__Scheduler_fail(__Crypto_NotSupported));
  }
});
