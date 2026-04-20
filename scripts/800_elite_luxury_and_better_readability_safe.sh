#!/usr/bin/env bash
set -euo pipefail

echo "==> 800_elite_luxury_and_better_readability_safe"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_800")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

changes = 0

def replace_once(old: str, new: str):
    global text, changes
    if old in text:
        text = text.replace(old, new, 1)
        changes += 1

# 1) Gjør reiseprofil-kortet mindre blendende hvitt
replace_once(
"""                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE6ECEF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reiseprofil',
""",
"""                decoration: BoxDecoration(
                  color: const Color(0xFFF6FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD9E6EA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reiseprofil',
""",
)

# 2) Gjør poengstatus-kortet mindre blendende hvitt
replace_once(
"""                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE6ECEF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Din poengstatus',
""",
"""                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDCE7EA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Din poengstatus',
""",
)

# 3) Gjør inputfelter tydeligere og mørkere
input_old = """decoration: const InputDecoration(
                        labelText: 'Reisemål',
                        hintText: 'f.eks Bangkok',
                        border: OutlineInputBorder(),
                      ),"""
input_new = """decoration: InputDecoration(
                        labelText: 'Reisemål',
                        hintText: 'f.eks Bangkok',
                        filled: true,
                        fillColor: const Color(0xFFFFFFFF),
                        labelStyle: const TextStyle(
                          color: Color(0xFF27414A),
                          fontWeight: FontWeight.w700,
                        ),
                        hintStyle: const TextStyle(
                          color: Color(0xFF6E848C),
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                        border: const OutlineInputBorder(),
                      ),"""
replace_once(input_old, input_new)

dropdown_targets = [
    ("Type tur",),
    ("Voksne",),
    ("Barn",),
    ("Antall dager",),
]

for (label,) in dropdown_targets:
    old = f"""decoration: const InputDecoration(
                              labelText: '{label}',
                              border: OutlineInputBorder(),
                            ),"""
    new = f"""decoration: InputDecoration(
                              labelText: '{label}',
                              filled: true,
                              fillColor: const Color(0xFFFFFFFF),
                              labelStyle: const TextStyle(
                                color: Color(0xFF27414A),
                                fontWeight: FontWeight.w700,
                              ),
                              contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                              border: const OutlineInputBorder(),
                            ),"""
    if old not in text:
        old = f"""decoration: const InputDecoration(
                        labelText: '{label}',
                        border: OutlineInputBorder(),
                      ),"""
        new = f"""decoration: InputDecoration(
                        labelText: '{label}',
                        filled: true,
                        fillColor: const Color(0xFFFFFFFF),
                        labelStyle: const TextStyle(
                          color: Color(0xFF27414A),
                          fontWeight: FontWeight.w700,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                        border: const OutlineInputBorder(),
                      ),"""
    replace_once(old, new)

sas_old = """decoration: InputDecoration(
                        labelText: 'Nåværende SAS EuroBonus-poeng',
                        hintText: 'f.eks 36797',
                        contentPadding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
                        border: const OutlineInputBorder(),
                      ),"""
sas_new = """decoration: InputDecoration(
                        labelText: 'Nåværende SAS EuroBonus-poeng',
                        hintText: 'f.eks 36797',
                        filled: true,
                        fillColor: const Color(0xFFFFFFFF),
                        labelStyle: const TextStyle(
                          color: Color(0xFF27414A),
                          fontWeight: FontWeight.w800,
                        ),
                        hintStyle: const TextStyle(
                          color: Color(0xFF6E848C),
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(16, 26, 16, 14),
                        border: const OutlineInputBorder(),
                      ),"""
replace_once(sas_old, sas_new)

# fallback hvis SAS-feltet fortsatt er const InputDecoration
sas_old2 = """decoration: const InputDecoration(
                        labelText: 'Nåværende SAS EuroBonus-poeng',
                        hintText: 'f.eks 36797',
                        border: OutlineInputBorder(),
                      ),"""
replace_once(sas_old2, sas_new)

# 4) Elite-badge mer luksus
replace_once(
"""                          child: Text(
                            'Elite: beste prioritering',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF8B6500),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
""",
"""                          child: Text(
                            'Elite: luksusnivå + beste prioritering',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF7A5600),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
""",
)

replace_once(
"""                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3D7),
                            borderRadius: BorderRadius.circular(999),
                          ),
""",
"""                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1CC),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFE7C66B)),
                          ),
""",
)

# 5) Gjør tittel/undertittel i poengstatus tydeligere
replace_once(
"""                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF5B7077),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
""",
"""                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF455C64),
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
""",
)

replace_once(
"""                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF5B7077),
                                fontWeight: FontWeight.w700,
                              ),
""",
"""                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF3F5760),
                                fontWeight: FontWeight.w800,
                              ),
""",
)

if text == orig or changes == 0:
    print("❌ Ingen sikre endringer ble gjort")
    print("Kjør og send:")
    print("  sed -n '860,1035p' lib/pages/travel_page.dart")
    raise SystemExit(1)

path.write_text(text)
print(f"✅ 800 ferdig, {changes} trygge endringer brukt")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
