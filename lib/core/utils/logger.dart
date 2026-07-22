import 'package:flutter/foundation.dart';

class Logger {
  static const bool verbose = true;

  static void d(String msg, {dynamic error, dynamic stackTrace}) {
    if (!verbose) return;
    debugPrint('$msg\n${error ?? ''}\n${stackTrace ?? ''}');
  }

  static void e(String msg, {dynamic error, dynamic stackTrace}) {
    debugPrint('ERROR: $msg\n${error ?? ''}\n${stackTrace ?? ''}');
  }
}
