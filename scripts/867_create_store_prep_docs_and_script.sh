#!/usr/bin/env bash
set -euo pipefail

mkdir -p docs/launch
mkdir -p scripts

cat > docs/launch/screenshots_checklist.md <<'MD'
# Bonusvarsel — Screenshots checklist

## Hovedmål
Vis appen som et ekte produkt, ikke som et dev-verktøy.

## Screenshot-idéer
- [ ] Hjem/feed med relevante bonuskampanjer
- [ ] Alerts-side med aktive varsler
- [ ] Toppvarsel / beste kampanje
- [ ] Tom-state som fortsatt ser bra ut
- [ ] Oversikt over varsler med tydelige badges

## Viktige regler
- [ ] Ingen Dev Hub i screenshots
- [ ] Ingen debug-tekster
- [ ] Konsistent språk
- [ ] Lesbar tekst
- [ ] Tydelig hierarki og grønne highlights der det gir mening

## Praktisk
- [ ] iPhone screenshots
- [ ] Android screenshots
- [ ] Velg 3–5 beste skjermbilder
- [ ] Bruk de samme hovedbudskapene i App Store og Play Store
MD

cat > docs/launch/store_submission_checklist.md <<'MD'
# Bonusvarsel — Store submission checklist

## Metadata
- [ ] Appnavn
- [ ] Kort beskrivelse
- [ ] Lang beskrivelse
- [ ] Keywords / søkeord
- [ ] Kategori
- [ ] Aldersrating
- [ ] Support e-post
- [ ] Nettside
- [ ] Privacy policy

## Assets
- [ ] Appikon
- [ ] Screenshots i riktige størrelser
- [ ] Eventuell promo-tekst

## Funksjonelt
- [ ] App starter uten dev-flagg
- [ ] Dev Hub skjult i prod
- [ ] Varsler-side fungerer
- [ ] Tom-state ser ryddig ut
- [ ] Ingen åpenbare debug-elementer

## Backend
- [ ] Prod-lignende config verifisert
- [ ] Dedupe realistisk for prod
- [ ] Dev-ruter deaktivert i prod
- [ ] Health-endpoint verifisert

## Innsending
- [ ] Intern test kjørt
- [ ] Release candidate bygget
- [ ] Store-skjema fylt ut
- [ ] Privacy policy koblet
- [ ] Sendt til review
MD

cat > docs/launch/contact_and_links.md <<'MD'
# Bonusvarsel — Contact and links

## Fyll inn før innsending
- Support e-post: SETT_INN
- Nettside: SETT_INN
- Privacy policy URL: SETT_INN
- Eventuell firmaadresse: SETT_INN

## App-navn
Bonusvarsel

## Kort pitch
Bonusvarsel hjelper brukere å oppdage relevante bonuskampanjer og holde oversikt over aktive varsler.

## Notater
Bruk samme kontaktinfo i:
- App Store
- Play Store
- privacy policy
- eventuell supportside
MD

cat > scripts/release_store_prep.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "== Bonusvarsel store prep =="

echo
echo "[1/5] Sjekker launch docs"
test -f docs/launch/app_store_text.md
test -f docs/launch/play_store_text.md
test -f docs/launch/privacy_policy.md
echo "✅ launch docs finnes"

echo
echo "[2/5] Sjekker store prep docs"
test -f docs/launch/screenshots_checklist.md
test -f docs/launch/store_submission_checklist.md
test -f docs/launch/contact_and_links.md
echo "✅ store prep docs finnes"

echo
echo "[3/5] Sjekker release scripts"
test -f scripts/release_checklist_run.sh
test -f scripts/run_prod_like_web.sh
test -f scripts/verify_dev_hub_hidden.sh
echo "✅ release scripts finnes"

echo
echo "[4/5] Kjører flutter analyze"
flutter analyze

echo
echo "[5/5] Oppsummering"
echo "✅ Store prep-basis er på plass"
echo "Neste: fyll inn kontaktinfo, ta screenshots, og kjør prod-lignende test"
SH

chmod +x scripts/release_store_prep.sh

echo "✅ Opprettet:"
echo " - docs/launch/screenshots_checklist.md"
echo " - docs/launch/store_submission_checklist.md"
echo " - docs/launch/contact_and_links.md"
echo " - scripts/release_store_prep.sh"
