#!/usr/bin/env bash
set -euo pipefail

echo "==> patch_803_verify_terminal_and_repo_context"
echo
echo "PWD:"
pwd
echo
echo "Git root:"
git rev-parse --show-toplevel 2>/dev/null || echo "❌ Ikke i git-repo"
echo
echo "Flutter pubspec:"
ls -la pubspec.yaml 2>/dev/null || echo "❌ Fant ikke pubspec.yaml her"
echo
echo "Bonusvarsel nøkkelfiler:"
ls -la lib/main.dart 2>/dev/null || true
ls -la lib/services/api_service.dart 2>/dev/null || true
ls -la lib/widgets/best_recommendation_card.dart 2>/dev/null || true
echo
echo "✅ Ferdig"
