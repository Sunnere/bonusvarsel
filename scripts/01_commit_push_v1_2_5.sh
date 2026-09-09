#!/bin/bash
set -e

cd ~/bonusvarsel

echo "== Status før commit =="
git status

git add -A
git commit -m "v1.2.5+37: iOS widget (EuroBonus + Trumf saldo), Kort-redesign, onboarding-forbedringer"
git push origin local-stable-baseline

echo "== Ferdig. Sjekk at push gikk gjennom over. =="
