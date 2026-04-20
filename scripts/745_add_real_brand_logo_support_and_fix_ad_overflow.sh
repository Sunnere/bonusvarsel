#!/usr/bin/env bash
set -euo pipefail

echo "==> 745_add_real_brand_logo_support_and_fix_ad_overflow"

mkdir -p assets/brands
mkdir -p docs
mkdir -p scripts

cat > assets/brands/README.txt <<'TXT'
Legg inn ekte logo-filer her med disse navnene når du har dem:

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

Tips:
- bruk PNG med transparent bakgrunn
- ca 256x256 eller 512x512
- korte filnavn med lowercase og underscore
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

def backup(path_str: str):
    p = Path(path_str)
    if p.exists():
        stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        bak = p.with_name(p.name + f".bak_{stamp}_745")
        shutil.copy2(p, bak)
        print(f"Backup: {bak}")

def ensure_pubspec_assets():
    p = Path("pubspec.yaml")
    if not p.exists():
        print("WARNING: pubspec.yaml not found")
        return
    text = p.read_text()
    changed = False
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
            changed = True
    if changed:
        backup("pubspec.yaml")
        p.write_text(text)
        print("Patched: pubspec.yaml")
    else:
        print("pubspec.yaml already includes brand assets or was left unchanged")

def patch_travel_page():
    p = Path("lib/pages/travel_page.dart")
    if not p.exists():
        print("WARNING: travel_page.dart not found")
        return
    text = p.read_text()
    original = text

    # Add logo resolver helpers if missing
    helper = """
  String _brandLogoForLabel(String label) {
    final key = label.toLowerCase();
    if (key.contains('sas')) return 'assets/brands/sas_eurobonus.png';
    if (key.contains('trumf')) return 'assets/brands/trumf.png';
    if (key.contains('visa')) return 'assets/brands/visa.png';
    if (key.contains('mastercard')) return 'assets/brands/mastercard.png';
    if (key.contains('amex')) return 'assets/brands/amex.png';
    if (key.contains('lunar')) return 'assets/brands/lunar.png';
    if (key.contains('allente')) return 'assets/brands/allente.png';
    if (key.contains('telia')) return 'assets/brands/telia.png';
    if (key.contains('ice')) return 'assets/brands/ice.png';
    if (key.contains('ishavskraft')) return 'assets/brands/ishavskraft.png';
    if (key.contains('bærum energi') or key.contains('baerum energi')) return 'assets/brands/baerum_energi.png';
    return '';
  }

"""
    if "_brandLogoForLabel(String label)" not in text:
        anchor = "  Widget _buildBrandStrip(BuildContext context) {\n"
        if anchor in text:
            text = text.replace(anchor, helper + anchor, 1)

    # Make store suggestion card show logos if brand file exists
    text = text.replace(
        "                Text(\n                  store.title,",
        """                Row(
                  children: [
                    _InlineBrandLogo(
                      assetPath: _brandLogoForLabel(store.title),
                      fallbackIcon: Icons.storefront,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        store.title,"""
    )
    text = text.replace(
        "                      ),\n                const SizedBox(height: 6),",
        """                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),"""
    )

    # Improve washed text in points section further
    text = text.replace(
        "Text(\n                        'Poengplan for familien',",
        "Text(\n                        'Poengplan for familien',"
    )
    text = text.replace(
        "Text(\n                        'Forsiktig familie-estimat for mål:",
        "Text(\n                        'Forsiktig familie-estimat for mål:"
    )
    text = text.replace(
        "Text('Nåværende saldo:",
        "Text('Nåværende saldo:"
    )
    text = text.replace(
        "Text('Estimert opptjening:",
        "Text('Estimert opptjening:"
    )

    # Add helper widget if missing
    helper_widget = """
class _InlineBrandLogo extends StatelessWidget {
  final String assetPath;
  final IconData fallbackIcon;

  const _InlineBrandLogo({
    required this.assetPath,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (assetPath.trim().isEmpty) {
      return Icon(fallbackIcon, color: const Color(0xFF0F6B73), size: 20);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        assetPath,
        width: 22,
        height: 22,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return Icon(fallbackIcon, color: const Color(0xFF0F6B73), size: 20);
        },
      ),
    );
  }
}
"""
    if "class _InlineBrandLogo extends StatelessWidget" not in text:
        anchor = "class _BrandBadge extends StatelessWidget {"
        if anchor in text:
            text = text.replace(anchor, helper_widget + "\n" + anchor, 1)
        else:
            text += "\n\n" + helper_widget + "\n"

    if text != original:
        backup(str(p))
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

    if "String _logoAssetForShopTitle(" not in text:
        helper = """
  String _logoAssetForShopTitle(String title) {
    final key = title.toLowerCase();
    if (key.contains('sas')) return 'assets/brands/sas_eurobonus.png';
    if (key.contains('trumf')) return 'assets/brands/trumf.png';
    if (key.contains('visa')) return 'assets/brands/visa.png';
    if (key.contains('mastercard')) return 'assets/brands/mastercard.png';
    if (key.contains('amex')) return 'assets/brands/amex.png';
    if (key.contains('lunar')) return 'assets/brands/lunar.png';
    if (key.contains('allente')) return 'assets/brands/allente.png';
    if (key.contains('telia')) return 'assets/brands/telia.png';
    if (key.contains('ice')) return 'assets/brands/ice.png';
    if (key.contains('ishavskraft')) return 'assets/brands/ishavskraft.png';
    if (key.contains('bærum energi') || key.contains('baerum energi')) return 'assets/brands/baerum_energi.png';
    return '';
  }

  Widget _shopLeadingLogo(String title) {
    final asset = _logoAssetForShopTitle(title);
    if (asset.isEmpty) {
      return const Icon(Icons.storefront, size: 22);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        asset,
        width: 22,
        height: 22,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.storefront, size: 22),
      ),
    );
  }

"""
        anchor = "  @override\n  Widget build(BuildContext context) {\n"
        if anchor in text:
            text = text.replace(anchor, helper + anchor, 1)

    # Replace common leading store icon patterns
    text = text.replace(
        "leading: const Icon(Icons.storefront_outlined),",
        "leading: _shopLeadingLogo(store.title),"
    )
    text = text.replace(
        "leading: const Icon(Icons.storefront),",
        "leading: _shopLeadingLogo(store.title),"
    )
    text = text.replace(
        "const Icon(Icons.storefront_outlined)",
        "_shopLeadingLogo(title)"
    )

    if text != original:
        backup(str(p))
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

    # Make any text inside ad cards ellipsized where obvious
    text = text.replace(
        "Text(",
        "Text(",
    )

    # Robust ad overflow helper additions
    if "_safeMaxLinesTitle" not in text:
        helper = """
  static const int _safeMaxLinesTitle = 2;
  static const int _safeMaxLinesBody = 2;

"""
        anchor = "class _AdSlotCardState extends State<AdSlotCard> {\n"
        if anchor in text:
            text = text.replace(anchor, anchor + helper, 1)

    # Constrain typical title/subtitle text if present
    text = re.sub(
        r"Text\(\s*([A-Za-z0-9_\.]+)\s*,\s*style:",
        r"Text(\n                    \1,\n                    maxLines: _safeMaxLinesTitle,\n                    overflow: TextOverflow.ellipsis,\n                    style:",
        text
    )

    text = text.replace(
        "child: Column(",
        "child: Column(\n              mainAxisSize: MainAxisSize.min,"
    )

    text = text.replace(
        "children: [",
        "children: ["
    )

    # Make rows/wraps more resilient
    text = text.replace(
        "child: Row(",
        "child: Row(\n              mainAxisSize: MainAxisSize.max,"
    )

    if text != original:
        backup(str(p))
        p.write_text(text)
        print("Patched: lib/widgets/ad_slot.dart")
    else:
        print("ad_slot.dart unchanged or no safe changes applied")

ensure_pubspec_assets()
patch_travel_page()
patch_eb_shopping_page()
patch_ad_slot()
PY

echo
echo "✅ 745 ferdig"
echo
echo "Legg inn ekte logo-filer i assets/brands/ med disse navnene:"
echo "  sas_eurobonus.png"
echo "  trumf.png"
echo "  visa.png"
echo "  mastercard.png"
echo "  amex.png"
echo "  lunar.png"
echo "  allente.png"
echo "  telia.png"
echo "  ice.png"
echo "  ishavskraft.png"
echo "  baerum_energi.png"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
