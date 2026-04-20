#!/usr/bin/env bash
set -euo pipefail

mkdir -p docs/launch

cat > docs/launch/release_checklist.md <<'MD'
# Bonusvarsel — Release checklist

## 1. MVP scope freeze
- [ ] Lås MVP-scope
- [ ] Ingen flere store Dev Hub-endringer før release-kandidat er testet
- [ ] Avklar hvilke sider som er sluttbruker-sider og hvilke som er dev-only

## 2. App readiness
- [ ] Verifiser onboarding
- [ ] Verifiser hovedfeed
- [ ] Verifiser varsler / alerts-side
- [ ] Verifiser preferanser / innstillinger
- [ ] Verifiser tomme states
- [ ] Verifiser feilvisning i UI
- [ ] Verifiser at app ikke er avhengig av Dev Hub for normal bruk

## 3. Dev/prod gating
- [ ] Skjul Dev Hub i prod
- [ ] Skjul/reset dev-ruter i prod
- [ ] Slå av `AUTO_DISABLE_DEDUPE` i prod
- [ ] Verifiser prod-env for API base URL
- [ ] Verifiser at dev-routes kun er aktivert i dev

## 4. Backend readiness
- [ ] Verifiser live fetch fungerer stabilt
- [ ] Verifiser scoring fungerer
- [ ] Verifiser smart dispatch fungerer
- [ ] Verifiser dedupe fungerer i realistisk modus
- [ ] Verifiser logging av fetch-feil
- [ ] Verifiser logging av dispatch-feil
- [ ] Verifiser health-endpoint

## 5. Notifications
- [ ] Test lokale varsler / push-flyt
- [ ] Test tom notification-state
- [ ] Test aktiv notification-state
- [ ] Verifiser at varsler ikke spammer
- [ ] Verifiser fallback når ingen kampanjer er relevante

## 6. UI / polish
- [ ] Sett riktig appnavn
- [ ] Sett appikon
- [ ] Sett splash / launch branding
- [ ] Verifiser farger, spacing og lesbarhet
- [ ] Verifiser at ingen debug-tekster vises i prod
- [ ] Verifiser at alle knapper gjør noe fornuftig

## 7. App Store / Play metadata
- [ ] Kort beskrivelse
- [ ] Lang beskrivelse
- [ ] Keywords / søkeord
- [ ] Screenshots
- [ ] Appikon i riktig format
- [ ] Support-kontakt
- [ ] Privacy policy URL / tekst
- [ ] Kategori og alder/rating
- [ ] Forklaring på varsler og databruk

## 8. Test
- [ ] Test på iPhone
- [ ] Test på Android
- [ ] Test onboarding fra blank state
- [ ] Test uten kampanjer
- [ ] Test med kampanjer
- [ ] Test med dispatch-resultater
- [ ] Test etter app restart
- [ ] Test mot dev backend
- [ ] Test mot prod-lignende backend

## 9. Release candidate
- [ ] Lag release branch
- [ ] Tag første release candidate
- [ ] Bygg iOS release
- [ ] Bygg Android release
- [ ] Kjør siste sanity check
- [ ] Last opp til intern testing

## 10. Launch
- [ ] Last opp metadata
- [ ] Last opp screenshots
- [ ] Koble privacy policy
- [ ] Send til review
- [ ] Dokumenter første produksjonsversjon
MD

cat > docs/launch/app_store_text.md <<'MD'
# Bonusvarsel — App Store text draft

## App name
Bonusvarsel

## Subtitle
Finn bonuskampanjer og smarte varsler

## Promotional text
Få oversikt over bonuskampanjer, oppdag gode poengmuligheter og motta varsler når relevante tilbud dukker opp.

## Short description
Bonusvarsel hjelper deg å oppdage bonuskampanjer og følge tilbud som kan gi mer verdi på netthandel og reiser.

## Long description
Bonusvarsel er laget for brukere som vil følge med på bonuskampanjer og få bedre oversikt over tilbud som kan gi ekstra verdi.

I appen kan du:
- følge bonuskampanjer
- se relevante tilbud samlet på ett sted
- få varsler når interessante kampanjer dukker opp
- holde oversikt over utvalgte bonusmuligheter

Bonusvarsel er laget for å gjøre det enklere å oppdage gode kampanjer uten å måtte lete manuelt hele tiden.

## Keywords
bonus, poeng, kampanjer, varsler, shopping, reise

## Support
Support e-post: SETT_INN
Nettside: SETT_INN
MD

cat > docs/launch/play_store_text.md <<'MD'
# Bonusvarsel — Play Store text draft

## App name
Bonusvarsel

## Short description
Oppdag bonuskampanjer og få varsler om relevante tilbud.

## Full description
Bonusvarsel hjelper deg å finne bonuskampanjer og holde oversikt over relevante tilbud på en enkel måte.

Med Bonusvarsel kan du:
- følge bonuskampanjer
- oppdage tilbud med ekstra verdi
- motta varsler om relevante kampanjer
- få bedre oversikt over utvalgte bonusmuligheter

Appen er laget for brukere som vil spare tid og få bedre kontroll på interessante bonusmuligheter.

## Contact
Support e-post: SETT_INN
Nettside: SETT_INN
MD

cat > docs/launch/privacy_policy.md <<'MD'
# Bonusvarsel — Privacy policy draft

## Innledning
Bonusvarsel respekterer personvernet ditt. Denne teksten er et utkast som må tilpasses før publisering.

## Hvilke data appen kan bruke
Bonusvarsel kan behandle:
- appinnstillinger og preferanser
- tekniske data som er nødvendige for at appen skal fungere
- varselrelaterte data dersom brukeren aktiverer varsler

## Hva data brukes til
Data brukes for å:
- levere innhold i appen
- vise relevante kampanjer
- sende varsler dersom brukeren ønsker det
- forbedre stabilitet og funksjon

## Deling av data
Bonusvarsel skal som hovedregel ikke selge personopplysninger. Eventuell deling med tekniske underleverandører må dokumenteres tydelig.

## Lagring
Data skal lagres bare så lenge det er nødvendig for appens funksjon eller for å oppfylle lovpålagte krav.

## Varsler
Hvis brukeren tillater varsler, kan appen sende meldinger om relevante kampanjer eller oppdateringer.

## Kontakt
Sett inn kontaktinformasjon før publisering.

## Viktig
Denne teksten må gjennomgås og tilpasses faktisk databruk før appen sendes inn til App Store eller Play Store.
MD

echo "✅ Opprettet:"
echo " - docs/launch/release_checklist.md"
echo " - docs/launch/app_store_text.md"
echo " - docs/launch/play_store_text.md"
echo " - docs/launch/privacy_policy.md"
