import 'dart:async';
import 'package:flutter/foundation.dart';

void setupErrorHandling() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);

    // TODO: send til Sentry/Crashlytics i prod
    if (kDebugMode) {
      // ignore: avoid_print
      print('FlutterError: ${details.exception}');
      // ignore: avoid_print
      print(details.stack);
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    // TODO: send til Sentry/Crashlytics i prod
    if (kDebugMode) {
      // ignore: avoid_print
      print('PlatformDispatcher error: $error');
      // ignore: avoid_print
      print(stack);
    }
    return true; // handled
  };

  runZonedGuarded(() {}, (Object error, StackTrace stack) {
    // TODO: send til Sentry/Crashlytics i prod
    if (kDebugMode) {
      // ignore: avoid_print
      print('runZonedGuarded error: $error');
      // ignore: avoid_print
      print(stack);
    }
  });
}
