import 'dart:js';

/// A workaround to converting an object from JS to a Dart Map.
Map jsToMap(JsObject jsObject) {
  return new Map.fromIterable(
    _getKeysOfObject(jsObject),
    value: (key) => jsObject[key],
  );
}

JsArray _getKeysOfObject(JsObject jsObject) => context['Object'].callMethod('keys', [jsObject]);