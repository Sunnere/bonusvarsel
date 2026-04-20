#!/usr/bin/env bash
set -euo pipefail

echo "==> 731_add_real_travel_photos_to_travel_page"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("ERROR: lib/pages/travel_page.dart not found")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_731")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text

hero_methods = """
  String _heroImageUrl() {
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

    if (isWinter) {
      return 'https://images.unsplash.com/photo-1516483638261-f4dbaf036963?auto=format&fit=crop&w=1600&q=80';
    }

    if (isBeach) {
      return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1600&q=80';
    }

    return 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?auto=format&fit=crop&w=1600&q=80';
  }

"""
if "_heroImageUrl()" not in text:
    anchor = "  Widget _buildBrandStrip(BuildContext context) {\n"
    if anchor not in text:
        print("ERROR: Could not find insertion anchor for hero methods")
        raise SystemExit(1)
    text = text.replace(anchor, hero_methods + anchor, 1)

text = text.replace(
    "Image.asset(",
    "Image.network(",
)

text = text.replace(
    "'assets/images/travel_hero.jpg'",
    "_heroImageUrl()",
)

# ensure hero image has graceful fallback
if "errorBuilder: (_, __, ___)" not in text:
    text = text.replace(
        "fit: BoxFit.cover,",
        """fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF0F3D5E),
                                Color(0xFF1B6B73),
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
        1,
    )

# replace _NeedTile class with image-backed version
needtile_pattern = re.compile(
    r"class _NeedTile extends StatelessWidget \{.*?\n\}\n$",
    re.DOTALL,
)

new_needtile = """
class _NeedTile extends StatelessWidget {
  final _PackingNeed need;

  const _NeedTile({required this.need});

  String _imageUrlForNeed() {
    final key = ('${need.label} ${need.category} ${need.storeHint}').toLowerCase();

    if (key.contains('bagasje') || key.contains('koffert')) {
      return 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80';
    }

    if (key.contains('passmapper') || key.contains('reiselommer')) {
      return 'https://images.unsplash.com/photo-1527631746610-bca00a040d60?auto=format&fit=crop&w=1200&q=80';
    }

    if (key.contains('powerbank') || key.contains('ladere') || key.contains('elektronikk')) {
      return 'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?auto=format&fit=crop&w=1200&q=80';
    }

    if (key.contains('barn') || key.contains('snacks') || key.contains('reiseaktiviteter')) {
      return 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?auto=format&fit=crop&w=1200&q=80';
    }

    if (key.contains('solkrem') || key.contains('apotek') || key.contains('helse')) {
      return 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=1200&q=80';
    }

    if (key.contains('badetøy') || key.contains('strand')) {
      return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80';
    }

    if (key.contains('snorkel')) {
      return 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=1200&q=80';
    }

    if (key.contains('ull') || key.contains('vinter') || key.contains('hansker') || key.contains('luer')) {
      return 'https://images.unsplash.com/photo-1516483638261-f4dbaf036963?auto=format&fit=crop&w=1200&q=80';
    }

    if (key.contains('sko')) {
      return 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=1200&q=80';
    }

    if (key.contains('sport')) {
      return 'https://images.unsplash.com/photo-1517649763962-0c623066013b?auto=format&fit=crop&w=1200&q=80';
    }

    return 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?auto=format&fit=crop&w=1200&q=80';
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
              height: 120,
              width: double.infinity,
              child: Image.network(
                _imageUrlForNeed(),
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

if "String _imageUrlForNeed()" not in text:
    m = needtile_pattern.search(text)
    if not m:
      # fallback replace from class _NeedTile to end of file
      start = text.find("class _NeedTile extends StatelessWidget {")
      if start == -1:
        print("ERROR: Could not find _NeedTile class")
        raise SystemExit(1)
      text = text[:start] + new_needtile
    else:
      text = text[:m.start()] + new_needtile
else:
    print("_NeedTile already appears image-backed; leaving existing version.")

# make the offers card description slightly stronger
text = text.replace(
    "Text(item.subtitle),",
    "Text(\n                                        item.subtitle,\n                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(\n                                              color: const Color(0xFF36535B),\n                                              fontWeight: FontWeight.w600,\n                                            ),\n                                      ),",
)

if text == original:
    print("No changes made.")
    raise SystemExit(0)

path.write_text(text)
print(f"Patched: {path}")
PY

echo
echo "✅ 731 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
