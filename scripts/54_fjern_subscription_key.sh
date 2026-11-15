#!/bin/bash
set -euo pipefail
cd "$HOME/bonusvarsel"
KEY="functions/keys/SubscriptionKey.p8"

if ! grep -qxF "functions/keys/" .gitignore 2>/dev/null; then
  printf '\n# Privat App Store-nøkkel – aldri i git\nfunctions/keys/\n*.p8\n' >> .gitignore
fi

if git ls-files --error-unmatch "$KEY" >/dev/null 2>&1; then
  git rm --cached "$KEY"
fi

git add .gitignore
if git diff --cached --quiet; then
  echo "Ingenting å committe."
else
  git commit -m "Fjern privat App Store-nøkkel fra git og ignorer functions/keys/"
fi
echo "Ferdig. Sjekk: git status"
