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
