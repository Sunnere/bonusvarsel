#!/bin/bash
# 43_flyhjelp_bilde.sh – bildeannonse: viser flyhjelp-banner.png i annonsekortet (Reise-fanen)
# Kjør:  bash scripts/43_flyhjelp_bilde.sh      (test på kopi:  REPO=/tmp/bv_test bash scripts/43_flyhjelp_bilde.sh)
set -e
REPO="${REPO:-$HOME/bonusvarsel}"
SRC="${IMG:-$HOME/Downloads/flyhjelp-banner.png}"
AD="$REPO/lib/services/ad_service.dart"
CARD="$REPO/lib/widgets/ad_slot.dart"
OUT="$REPO/assets/brands/flyhjelp_banner.jpg"
[ -f "$AD" ] && [ -f "$CARD" ] || { echo "FEIL: fant ikke ad_service.dart / ad_slot.dart i $REPO"; exit 1; }
[ -f "$SRC" ] || { echo "FEIL: fant ikke bildet $SRC"; exit 1; }
grep -q "id: 'flyhjelp_1'" "$AD" || { echo "FEIL: kjør scripts/42_flyhjelp_annonse.sh først"; exit 1; }
cp -n "$AD" "$AD.bak_43" || true
cp -n "$CARD" "$CARD.bak_43" || true

# 1) Bilde: nedskalert JPEG (1000 px) så appen ikke blir tung
mkdir -p "$REPO/assets/brands"
sips -s format jpeg -s formatOptions 85 -Z 1000 "$SRC" --out "$OUT" >/dev/null
echo "Bilde: $OUT ($(du -k "$OUT" | cut -f1) KB)"

python3 - "$AD" "$CARD" <<'PY'
import sys
ad_path, card_path = sys.argv[1], sys.argv[2]

# 2) Koble bildet til annonsen
ad = open(ad_path, encoding="utf-8").read()
if "flyhjelp_banner.jpg" in ad:
    print("ad_service.dart: bilde allerede koblet - hopper over")
else:
    old = "id: 'flyhjelp_1',\n          isSponsored: true,"
    if ad.count(old) != 1:
        sys.exit("FEIL: fant ikke flyhjelp_1-blokken akkurat én gang")
    new = old + "\n          imageUrl: 'assets/brands/flyhjelp_banner.jpg',"
    open(ad_path, "w", encoding="utf-8").write(ad.replace(old, new))
    print("ad_service.dart: imageUrl lagt til på flyhjelp_1")

# 3) Kortet kan vise bilde (bare annonser med imageUrl endres - alle andre er uberørt)
card = open(card_path, encoding="utf-8").read()
if "_imageCard(" in card:
    print("ad_slot.dart: bildekort finnes fra før - hopper over")
else:
    anchor1 = "    return Padding(\n      padding: const EdgeInsets.symmetric(vertical: 8),\n      child: Opacity("
    anchor2 = "  Widget _tierChip({"
    if card.count(anchor1) != 1 or card.count(anchor2) != 1:
        sys.exit("FEIL: fant ikke forventede steder i ad_slot.dart")
    early = (
        "    final img = slot.imageUrl;\n"
        "    if (img != null && img.isNotEmpty && !_isLocked) {\n"
        "      return _imageCard(img, cta);\n"
        "    }\n\n"
    )
    method = '''  Widget _imageCard(String img, String cta) {
    final Widget image = img.startsWith('http')
        ? Image.network(
            img,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(height: 160),
          )
        : Image.asset(img, fit: BoxFit.cover);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF163A70),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  AspectRatio(aspectRatio: 1, child: image),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Annonse',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: BrandTheme.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _handleTap,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(
                    cta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

'''
    card = card.replace(anchor1, early + anchor1).replace(anchor2, method + anchor2)
    open(card_path, "w", encoding="utf-8").write(card)
    print("ad_slot.dart: la inn bildekort")
PY

echo
echo "== Kontroll"
grep -n "flyhjelp_banner.jpg" "$AD"
grep -n "_imageCard" "$CARD"
if command -v flutter >/dev/null 2>&1; then
  echo
  echo "== flutter analyze (kun feil)"
  (cd "$REPO" && flutter analyze --no-pub lib/services/ad_service.dart lib/widgets/ad_slot.dart 2>&1 | grep -E " error •" || echo "Ingen feil")
fi
echo
echo "Ferdig. Backup: *.bak_43. Test: flutter run -> Reise-fanen skal vise bildet med «Annonse» og knapp under."
