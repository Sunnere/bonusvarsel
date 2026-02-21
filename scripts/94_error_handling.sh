#!/usr/bin/env bash
set -euo pipefail

mkdir -p lib/app

ERR="lib/app/error_handling.dart"
[ -f "$ERR" ] && cp "$ERR" "$ERR.bak.$(date +%s)" || true

cat > "$ERR" <<'DART'
import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
DART

MAIN="lib/main.dart"
if [[ ! -f "$MAIN" ]]; then
  echo "Fant ikke lib/main.dart"
  exit 1
fi

cp "$MAIN" "$MAIN.bak.$(date +%s)"

python3 - "$MAIN" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

if "lib/app/error_handling.dart" not in s:
  # legg inn import etter første import-blokk
  m = re.search(r"^(import .*\n)+", s, flags=re.M)
  if m:
    ins = m.group(0) + "import 'app/error_handling.dart';\n"
    s = s[:m.start()] + ins + s[m.end():]
  else:
    s = "import 'app/error_handling.dart';\n" + s

# sørg for setupErrorHandling() i main()
# case 1: main() finnes
m = re.search(r"void\s+main\s*\(\s*\)\s*\{", s)
if m:
  # hvis allerede kalt, ikke dupliser
  if "setupErrorHandling();" not in s[m.end():m.end()+300]:
    s = s[:m.end()] + "\n  setupErrorHandling();\n" + s[m.end():]
else:
  # ingen main? legg en på toppen
  s = "void main(){\n  setupErrorHandling();\n}\n\n" + s

p.write_text(s, encoding="utf-8")
print("patched main.dart: setupErrorHandling() + import")
PY

dart format "$ERR" "$MAIN"
echo "✅ 1) Error handling aktivert"
