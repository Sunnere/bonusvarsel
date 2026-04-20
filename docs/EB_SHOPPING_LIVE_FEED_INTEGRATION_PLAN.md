# EB Shopping live feed integration plan

## Mål
Koble kun `eb_shopping_page.dart` til backend offers feed, med fallback til legacy offers.

## Regler
- Ikke migrer hele appen nå
- Ikke skriv om hele widget-treet
- Bytt kun datasource først
- Legacy skal fortsatt fungere hvis live feed feiler eller er tom

## Filer opprettet
- `lib/features/offers/eb_shopping_offer_vm.dart`
- `lib/features/offers/eb_shopping_offers_adapter.dart`
- `lib/features/offers/eb_shopping_offers_datasource.dart`

## Trygg patch-strategi
1. Importer datasource + vm i `eb_shopping_page.dart`
2. Opprett lokal loader:
   - prøv live feed
   - fallback til legacy
3. Bruk eksisterende render-flow
4. Ikke endre design, bare datasource
5. Kjør analyze
6. Test live, tom feed, feil, deeplink

## Ting som ikke skal gjøres i samme patch
- ny layout
- ny filtermotor
- full app-migrering
- ny card-komponent
- aggressiv cleanup
