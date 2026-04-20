#!/usr/bin/env bash
set -euo pipefail

TARGET="lib/config/app_env.dart"

mkdir -p lib/config

cat > "$TARGET" <<'DART'
class AppEnv {
  static const bool isProd = false;
  static const String appFlavor = 'dev';
}
DART

echo "✅ app_env.dart opprettet"

flutter analyze
echo "✅ 877 ferdig"
