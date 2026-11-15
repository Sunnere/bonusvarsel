#!/bin/bash
# 60: Commit 1.3.2 i fire commits, rebase mot origin og push. Stopper ved feil.
# Kjør: bash scripts/60_commit_og_push_132.sh   (REPO=... for annen mappe, NOPUSH=1 for å hoppe over push)
set -euo pipefail
REPO="${REPO:-$HOME/bonusvarsel}"
BRANCH="local-stable-baseline"
cd "$REPO"

CUR=$(git branch --show-current)
[ "$CUR" = "$BRANCH" ] || { echo "❌ Du står på '$CUR', ikke '$BRANCH'. Avbryter."; exit 1; }

TRAILER=$'\n\nCo-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>\nClaude-Session: https://claude.ai/code/session_01JCzUnP92PBE6fQmscifznL'

commit_if_staged() {
  if git diff --cached --quiet; then
    echo "⏭  Ingenting å committe: $1"
  else
    git commit -q -m "$1$TRAILER"
    echo "✅ Commit: $1"
  fi
}

# 4 (først, så .gitignore virker): ignorer rot-søppel
for p in "Claude outputs/" "launchd_disabled/" "generate_campaign_image.py" "openai_test_image.py"; do
  grep -qxF "$p" .gitignore || echo "$p" >> .gitignore
done

# 1: versjon 1.3.2+40, bilde-import og Flyhjelp-banner
for f in pubspec.yaml pubspec.lock assets/brands/flyhjelp_banner.jpg \
         ios/Podfile ios/Podfile.lock ios/Runner.xcodeproj/project.pbxproj ios/Runner/Info.plist \
         macos/Podfile macos/Podfile.lock macos/Runner.xcodeproj/project.pbxproj \
         macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter/generated_plugin_registrant.cc \
         linux/flutter/generated_plugins.cmake; do
  [ -e "$f" ] && git add -- "$f"
done
commit_if_staged "1.3.2+40: image_picker, iOS 15, Flyhjelp-banner"

# 2: lint-opprydding i lib/
git add lib
commit_if_staged "Rydd ubrukte importer og felt i lib"

# 3: scripts
git add scripts
commit_if_staged "Legg til nummererte scripts 01-60"

# 4: .gitignore
git add .gitignore
commit_if_staged "Ignorer lokale arbeidsmapper og testskript"

echo "== Rebase mot origin/$BRANCH"
git pull --rebase --autostash origin "$BRANCH"

if [ "${NOPUSH:-0}" = "1" ]; then
  echo "NOPUSH=1: hopper over push."
else
  git push origin "$BRANCH"
  echo "✅ Pushet til origin/$BRANCH"
fi
git log --oneline -6
