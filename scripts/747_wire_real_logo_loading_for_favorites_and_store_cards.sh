#!/usr/bin/env bash
set -euo pipefail

echo "==> 747_wire_real_logo_loading_for_favorites_and_store_cards"

mkdir -p assets/brands
mkdir -p docs
mkdir -p scripts

cat > assets/brands/README.txt <<'TXT'
Legg ekte logo-filer her når du har dem.

Anbefalte filnavn:
sas_eurobonus.png
trumf.png
visa.png
mastercard.png
amex.png
lunar.png
allente.png
telia.png
ice.png
ishavskraft.png
baerum_energi.png

zalando.png
nike.png
adidas.png
komplett.png
power.png
elkjop.png
apotek1.png
vita.png
blivakker.png
boozt.png
ellos.png
cdon.png

Bruk:
- PNG med transparent bakgrunn
- 256x256 eller 512x512 fungerer fint
- lowercase + underscore
TXT

cat > docs/AI_RULES.md <<'TXT'
Alle kodeendringer skal leveres som cat-scripts som oppretter eller oppdaterer filer under scripts/.
Ikke lever lim-inn-kode som krever manuell redigering i lib/.
TXT

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

def backup(path_str: str, tag: str):
    p = Path(path_str)
    if p.exists():
        stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        bak = p.with_name(p.name + f".bak_{stamp}_{tag}")
        shutil.copy2(p, bak)
        print(f"Backup: {bak}")

def ensure_pubspec_assets():
    p = Path("pubspec.yaml")
    if not p.exists():
        print("WARNING: pubspec.yaml not found")
        return
    text = p.read_text()
    original = text

    if "assets/brands/" not in text:
        if re.search(r"(?m)^flutter:\s*$", text):
            if re.search(r"(?m)^  assets:\s*$", text):
                text = re.sub(
                    r"(?m)^  assets:\s*$",
                    "  assets:\n    - assets/images/travel/\n    - assets/brands/\n",
                    text,
                    count=1,
                )
            else:
                text = re.sub(
                    r"(?m)^flutter:\s*$",
                    "flutter:\n  assets:\n    - assets/images/travel/\n    - assets/brands/\n",
                    text,
                    count=1,
                )

    if text != original:
        backup("pubspec.yaml", "747")
        p.write_text(text)
        print("Patched: pubspec.yaml")
    else:
        print("pubspec.yaml unchanged")

def patch_travel_page():
    p = Path("lib/pages/travel_page.dart")
    if not p.exists():
        print("WARNING: travel_page.dart not found")
        return

    text = p.read_text()
    original = text

    helper = """
  String _brandLogoForLabel(String label) {
    final key = label.toLowerCase().trim();

    if (key.contains('sas')) return 'assets/brands/sas_eurobonus.png';
    if (key.contains('trumf')) return 'assets/brands/trumf.png';
    if (key.contains('visa')) return 'assets/brands/visa.png';
    if (key.contains('mastercard')) return 'assets/brands/mastercard.png';
    if (key.contains('amex')) return 'assets/brands/amex.png';
    if (key.contains('lunar')) return 'assets/brands/lunar.png';

    if (key.contains('allente')) return 'assets/brands/allente.png';
    if (key.contains('telia')) return 'assets/brands/telia.png';
    if (key == 'ice' || key.contains(' ice ')) return 'assets/brands/ice.png';
    if (key.contains('ishavskraft')) return 'assets/brands/ishavskraft.png';
    if (key.contains('bærum energi') || key.contains('baerum energi')) return 'assets/brands/baerum_energi.png';

    if (key.contains('zalando')) return 'assets/brands/zalando.png';
    if (key.contains('nike')) return 'assets/brands/nike.png';
    if (key.contains('adidas')) return 'assets/brands/adidas.png';
    if (key.contains('komplett')) return 'assets/brands/komplett.png';
    if (key.contains('power')) return 'assets/brands/power.png';
    if (key.contains('elkjøp') || key.contains('elkjop')) return 'assets/brands/elkjop.png';
    if (key.contains('apotek 1') || key.contains('apotek1')) return 'assets/brands/apotek1.png';
    if (key.contains('vita')) return 'assets/brands/vita.png';
    if (key.contains('blivakker')) return 'assets/brands/blivakker.png';
    if (key.contains('boozt')) return 'assets/brands/boozt.png';
    if (key.contains('ellos')) return 'assets/brands/ellos.png';
    if (key.contains('cdon')) return 'assets/brands/cdon.png';

    return '';
  }

"""
    if "_brandLogoForLabel(String label)" not in text:
        anchor = "  Widget _buildBrandStrip(BuildContext context) {\n"
        if anchor in text:
            text = text.replace(anchor, helper + anchor, 1)

    # make store cards use inline logo if available
    if "_InlineBrandLogo(" in text:
        text = text.replace(
            "_InlineBrandLogo(\n                      assetPath: _brandLogoForLabel(store.title),\n                      fallbackIcon: Icons.storefront,\n                    )",
            "_InlineBrandLogo(\n                      assetPath: _brandLogoForLabel(store.title),\n                      fallbackIcon: Icons.storefront,\n                      labelForFallback: store.title,\n                    )"
        )

    helper_widget = """
class _InlineBrandLogo extends StatelessWidget {
  final String assetPath;
  final IconData fallbackIcon;
  final String? labelForFallback;

  const _InlineBrandLogo({
    required this.assetPath,
    required this.fallbackIcon,
    this.labelForFallback,
  });

  @override
  Widget build(BuildContext context) {
    if (assetPath.trim().isEmpty) {
      return _fallbackBadge();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        assetPath,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return _fallbackBadge();
        },
      ),
    );
  }

  Widget _fallbackBadge() {
    final text = (labelForFallback ?? '').trim();
    if (text.isNotEmpty) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFFE7F1F7),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          text.characters.first.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF1E4B59),
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      );
    }

    return Icon(fallbackIcon, color: const Color(0xFF0F6B73), size: 20);
  }
}
"""
    text = re.sub(
        r"class _InlineBrandLogo extends StatelessWidget \{.*?\n\}\nclass _BrandBadge extends StatelessWidget \{",
        helper_widget + "\nclass _BrandBadge extends StatelessWidget {",
        text,
        flags=re.DOTALL
    )

    if text != original:
        backup(str(p), "747")
        p.write_text(text)
        print("Patched: lib/pages/travel_page.dart")
    else:
        print("travel_page.dart unchanged")

def patch_eb_shopping_page():
    p = Path("lib/pages/eb_shopping_page.dart")
    if not p.exists():
        print("WARNING: eb_shopping_page.dart not found")
        return

    text = p.read_text()
    original = text

    helper = """
  String _logoAssetForShopTitle(String title) {
    final key = title.toLowerCase().trim();

    if (key.contains('sas')) return 'assets/brands/sas_eurobonus.png';
    if (key.contains('trumf')) return 'assets/brands/trumf.png';
    if (key.contains('visa')) return 'assets/brands/visa.png';
    if (key.contains('mastercard')) return 'assets/brands/mastercard.png';
    if (key.contains('amex')) return 'assets/brands/amex.png';
    if (key.contains('lunar')) return 'assets/brands/lunar.png';

    if (key.contains('allente')) return 'assets/brands/allente.png';
    if (key.contains('telia')) return 'assets/brands/telia.png';
    if (key == 'ice' || key.contains(' ice ')) return 'assets/brands/ice.png';
    if (key.contains('ishavskraft')) return 'assets/brands/ishavskraft.png';
    if (key.contains('bærum energi') || key.contains('baerum energi')) return 'assets/brands/baerum_energi.png';

    if (key.contains('zalando')) return 'assets/brands/zalando.png';
    if (key.contains('nike')) return 'assets/brands/nike.png';
    if (key.contains('adidas')) return 'assets/brands/adidas.png';
    if (key.contains('komplett')) return 'assets/brands/komplett.png';
    if (key.contains('power')) return 'assets/brands/power.png';
    if (key.contains('elkjøp') || key.contains('elkjop')) return 'assets/brands/elkjop.png';
    if (key.contains('apotek 1') || key.contains('apotek1')) return 'assets/brands/apotek1.png';
    if (key.contains('vita')) return 'assets/brands/vita.png';
    if (key.contains('blivakker')) return 'assets/brands/blivakker.png';
    if (key.contains('boozt')) return 'assets/brands/boozt.png';
    if (key.contains('ellos')) return 'assets/brands/ellos.png';
    if (key.contains('cdon')) return 'assets/brands/cdon.png';

    return '';
  }

  Widget _shopLeadingLogo(String title) {
    final asset = _logoAssetForShopTitle(title);

    if (asset.isEmpty) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFFE7F1F7),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          title.trim().isNotEmpty ? title.trim().characters.first.toUpperCase() : '?',
          style: const TextStyle(
            color: Color(0xFF1E4B59),
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        asset,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F1F7),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              title.trim().isNotEmpty ? title.trim().characters.first.toUpperCase() : '?',
              style: const TextStyle(
                color: Color(0xFF1E4B59),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }

"""
    # Replace existing helper block fully if present
    text = re.sub(
        r"  String _logoAssetForShopTitle\(String title\) \{.*?  @override\n  Widget build\(BuildContext context\) \{",
        helper + "  @override\n  Widget build(BuildContext context) {",
        text,
        flags=re.DOTALL
    )

    # Try common leading replacement patterns
    text = text.replace(
        "leading: const Icon(Icons.storefront_outlined),",
        "leading: _shopLeadingLogo(store.title),"
    )
    text = text.replace(
        "leading: const Icon(Icons.storefront),",
        "leading: _shopLeadingLogo(store.title),"
    )
    text = text.replace(
        "leading: _shopLeadingLogo(title),",
        "leading: _shopLeadingLogo(title),"
    )

    # strengthen text readability on cards
    text = text.replace(
        "style: Theme.of(context).textTheme.titleLarge?.copyWith(",
        "style: Theme.of(context).textTheme.titleLarge?.copyWith("
    )

    if text != original:
        backup(str(p), "747")
        p.write_text(text)
        print("Patched: lib/pages/eb_shopping_page.dart")
    else:
        print("eb_shopping_page.dart unchanged")

def patch_ad_slot():
    p = Path("lib/widgets/ad_slot.dart")
    if not p.exists():
        print("WARNING: ad_slot.dart not found")
        return

    text = p.read_text()
    original = text

    # Remove duplicate mainAxisSize if any remain
    text = re.sub(
        r"(mainAxisSize:\s*MainAxisSize\.min,\s*)(?=.*mainAxisSize:\s*MainAxisSize\.min,)",
        "",
        text,
        count=1,
        flags=re.DOTALL
    )

    # Guard against overflow with Flexible wrappers in common text areas
    text = text.replace(
        "child: Column(",
        "child: Column(\n              mainAxisSize: MainAxisSize.min,"
    )

    # clean accidental duplicates
    text = text.replace(
        "mainAxisSize: MainAxisSize.min,\n              mainAxisSize: MainAxisSize.min,",
        "mainAxisSize: MainAxisSize.min,"
    )

    if text != original:
        backup(str(p), "747")
        p.write_text(text)
        print("Patched: lib/widgets/ad_slot.dart")
    else:
        print("ad_slot.dart unchanged")

ensure_pubspec_assets()
patch_travel_page()
patch_eb_shopping_page()
patch_ad_slot()
PY

echo
echo "✅ 747 ferdig"
echo
echo "Legg ekte logoer i assets/brands/ når du har dem."
echo "Inntil da får du trygg fallback med initial-badge."
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
