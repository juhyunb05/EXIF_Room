// ignore_for_file: uri_does_not_exist
import 'dart:js_util' as js_util;

Future<String> convertHeicWeb(String currentPath) async {
  final promise = js_util.callMethod(js_util.globalThis, 'convertHeicToJpeg', [currentPath]);
  return await js_util.promiseToFuture<String>(promise);
}
