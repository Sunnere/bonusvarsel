#!/usr/bin/env bash
set -euo pipefail

echo "==> 732_switch_travel_page_to_local_real_images"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

travel = Path("lib/pages/travel_page.dart")
pubspec = Path("pubspec.yaml")
assets_dir = Path("assets/images/travel")

if not travel.exists():
    print("ERROR: lib/pages/travel_page.dart not found")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = travel.with_name(travel.name + f".bak_{stamp}_732")
shutil.copy2(travel, bak)
print(f"Backup: {bak}")

assets_dir.mkdir(parents=True, exist_ok=True)

readme = assets_dir / "README_TRAVEL_IMAGES.txt"
readme.write_text(
"""Legg inn ekte bilder med disse filnavnene:

hero_beach.jpg
hero_winter.jpg
hero_city.jpg

need_luggage.jpg
need_passport.jpg
need_powerbank.jpg
need_kids.jpg
need_sunscreen.jpg
need_swimwear.jpg
need_snorkel.jpg
need_winter.jpg
need_shoes.jpg
need_sport.jpg
need_generic.jpg

Anbefalt stil:
- ekte foto
- høy kvalitet
- lys, varm, troverdig
- familie / reise / bagasje / strand / vinter
"""
)
print(f"Created: {readme}")

text = travel.read_text()
original = text

hero_helper = """
  String _heroAssetForTrip() {
    final destination = _destinationCtrl.text.trim().toLowerCase();

    final isWinter =
        destination.contains('ski') ||
        destination.contains('vinter') ||
        destination.contains('trysil') ||
        destination.contains('hafjell') ||
        destination.contains('geilo') ||
        _selectedTripType == 'Vintertur';

    final isBeach =
        destination.contains('thailand') ||
        destination.contains('spania') ||
        destination.contains('mallorca') ||
        destination.contains('gran canaria') ||
        destination.contains('kreta') ||
        destination.contains('hellas') ||
        destination.contains('phuket') ||
        destination.contains('krabi') ||
        _selectedTripType == 'Strandferie' ||
        _selectedTripType == 'Familieferie';

    if (isWinter) return 'assets/images/travel/hero_winter.jpg';
    if (isBeach) return 'assets/images/travel/hero_beach.jpg';
    return 'assets/images/travel/hero_city.jpg';
  }

"""
if "_heroAssetForTrip()" not in text:
    anchor = "  Widget _buildBrandStrip(BuildContext context) {\n"
    if anchor in text:
        text = text.replace(anchor, hero_helper + anchor, 1)
    else:
        print("ERROR: Could not insert _heroAssetForTrip helper")
        raise SystemExit(1)

# Switch hero from network/asset old paths to local asset helper
text = re.sub(
    r"Image\.(network|asset)\(\s*_heroImageUrl\(\),",
    "Image.asset(_heroAssetForTrip(),",
    text,
)
text = re.sub(
    r"Image\.(network|asset)\(\s*'assets/images/travel_hero\.jpg',",
    "Image.asset(_heroAssetForTrip(),",
    text,
)

# Ensure hero fallback is local-safe and elegant
text = re.sub(
    r"errorBuilder:\s*\(_, __, ___\)\s*\{.*?\},",
    """errorBuilder: (_, __, ___) {
                        return Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF103E74),
                                Color(0xFF0F6B73),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.flight_takeoff,
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                        );
                      },""",
    text,
    count=1,
    flags=re.DOTALL,
)

# Replace _NeedTile with local asset version
start = text.find("class _NeedTile extends StatelessWidget {")
if start == -1:
    print("ERROR: Could not find _NeedTile class")
    raise SystemExit(1)

new_need_tile = """
class _NeedTile extends StatelessWidget {
  final _PackingNeed need;

  const _NeedTile({required this.need});

  String _assetForNeed() {
    final key = ('${need.label} ${need.category} ${need.storeHint}').toLowerCase();

    if (key.contains('bagasje') || key.contains('koffert')) {
      return 'assets/images/travel/need_luggage.jpg';
    }
    if (key.contains('passmapper') || key.contains('reiselommer')) {
      return 'assets/images/travel/need_passport.jpg';
    }
    if (key.contains('powerbank') || key.contains('ladere') || key.contains('elektronikk')) {
      return 'assets/images/travel/need_powerbank.jpg';
    }
    if (key.contains('barn') || key.contains('snacks') || key.contains('reiseaktiviteter')) {
      return 'assets/images/travel/need_kids.jpg';
    }
    if (key.contains('solkrem') || key.contains('apotek') || key.contains('helse')) {
      return 'assets/images/travel/need_sunscreen.jpg';
    }
    if (key.contains('badetøy') || key.contains('strand')) {
      return 'assets/images/travel/need_swimwear.jpg';
    }
    if (key.contains('snorkel')) {
      return 'assets/images/travel/need_snorkel.jpg';
    }
    if (key.contains('ull') || key.contains('vinter') || key.contains('hansker') || key.contains('luer')) {
      return 'assets/images/travel/need_winter.jpg';
    }
    if (key.contains('sko')) {
      return 'assets/images/travel/need_shoes.jpg';
    }
    if (key.contains('sport')) {
      return 'assets/images/travel/need_sport.jpg';
    }
    return 'assets/images/travel/need_generic.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final isHigh = need.priority == 'Høy';
    final isMedium = need.priority == 'Middels';

    final bg = isHigh
        ? const Color(0xFFF7DEC2)
        : isMedium
            ? const Color(0xFFE5F0EE)
            : const Color(0xFFF4EEE4);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: Image.asset(
                _assetForNeed(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1B6B73),
                          Color(0xFF0F3D5E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.luggage,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  need.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF183038),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Antall: ${need.quantity}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF36535B),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Prioritet: ${need.priority}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF36535B),
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Kategori: ${need.category}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF36535B),
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Se etter butikker i appen for: ${need.storeHint}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF36535B),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
"""
text = text[:start] + new_need_tile

if text == original:
    print("No changes made to travel_page.dart")
else:
    travel.write_text(text)
    print(f"Patched: {travel}")

if not pubspec.exists():
    print("WARNING: pubspec.yaml not found")
    raise SystemExit(0)

pub = pubspec.read_text()
if "assets/images/travel/" not in pub:
    if re.search(r"(?m)^flutter:\s*$", pub):
        if re.search(r"(?m)^  assets:\s*$", pub):
            pub = re.sub(
                r"(?m)^  assets:\s*$",
                "  assets:\n    - assets/images/travel/\n",
                pub,
                count=1,
            )
        else:
            pub = re.sub(
                r"(?m)^flutter:\s*$",
                "flutter:\n  assets:\n    - assets/images/travel/\n",
                pub,
                count=1,
            )
        pubspec.write_text(pub)
        print(f"Patched: {pubspec}")
    else:
        print("WARNING: Could not safely patch pubspec.yaml automatically")
PY

echo
echo "✅ 732 ferdig"
echo
echo "Legg nå inn ekte bilder i disse filene:"
echo "  assets/images/travel/hero_beach.jpg"
echo "  assets/images/travel/hero_winter.jpg"
echo "  assets/images/travel/hero_city.jpg"
echo "  assets/images/travel/need_luggage.jpg"
echo "  assets/images/travel/need_passport.jpg"
echo "  assets/images/travel/need_powerbank.jpg"
echo "  assets/images/travel/need_kids.jpg"
echo "  assets/images/travel/need_sunscreen.jpg"
echo "  assets/images/travel/need_swimwear.jpg"
echo "  assets/images/travel/need_snorkel.jpg"
echo "  assets/images/travel/need_winter.jpg"
echo "  assets/images/travel/need_shoes.jpg"
echo "  assets/images/travel/need_sport.jpg"
echo "  assets/images/travel/need_generic.jpg"
echo
echo "Kjør så:"
echo "  flutter pub get"
echo "  flutter run -d macos"
