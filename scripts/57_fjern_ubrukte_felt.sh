# 57: Fjerner ubrukte private felt (unused_field) som er trygt å fjerne.
# Et felt fjernes kun når:
#   - deklarasjonen står på én linje og linjen slutter på ;
#   - navnet bare forekommer én gang i filen (selve deklarasjonen), slik at ingen kode brytes.
# Alt annet hoppes over og listes. Ubrukte funksjoner, lokale variabler og logikk endres ikke.
# Kjør fra Terminal:
#   bash ~/bonusvarsel/scripts/57_fjern_ubrukte_felt.sh
# Test-miljø: BV_REPO=/sti/til/kopi FLUTTER_BIN=/sti/til/fake-flutter bash scripts/57_fjern_ubrukte_felt.sh
set -euo pipefail

REPO="${BV_REPO:-$HOME/bonusvarsel}"
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
cd "$REPO"

TS="$(date +%Y%m%d_%H%M%S)"
BACKUP=".script_backups/57_${TS}"
mkdir -p "$BACKUP"

"$FLUTTER_BIN" analyze --no-pub > "$BACKUP/analyze.txt" 2>/dev/null || true

python3 - "$BACKUP" <<'PYEOF'
import sys, os, re, shutil
backup = sys.argv[1]
with open(os.path.join(backup, "analyze.txt"), encoding="utf-8", errors="replace") as fh:
    text = fh.read()

text = re.sub(r"\n\s{4,}", " ", text)
records = re.split(r"\n(?=\s*(?:error|warning|info) •)", text)

fields = {}  # path -> list of (line, name)
for rec in records:
    rec = " ".join(rec.split())
    if not re.search(r"\bunused_field\b(\s+\d+ issues? found\..*)?\s*$", rec):
        continue
    m_loc = re.search(r"(lib/[^\s:]+\.dart):(\d+):(\d+)", rec)
    m_name = re.search(r"field '(\w+)'", rec)
    if not m_loc or not m_name:
        continue
    fields.setdefault(m_loc.group(1), []).append((int(m_loc.group(2)), m_name.group(1)))

if not fields:
    print("Ingen ubrukte felt funnet.")
    raise SystemExit(0)

plans = {}
skipped = []
removed = 0
for path in sorted(fields):
    if not os.path.isfile(path):
        skipped.append((path, "fil finnes ikke", ""))
        continue
    with open(path, encoding="utf-8") as fh:
        lines = fh.readlines()
    full = "".join(lines)
    to_delete = set()
    for line_no, name in fields[path]:
        idx = line_no - 1
        if idx < 0 or idx >= len(lines):
            skipped.append((path, "linje finnes ikke", name))
            continue
        cur = lines[idx]
        stripped = cur.strip()
        if not stripped.endswith(";") or "{" in stripped:
            skipped.append((path, "deklarasjonen er ikke én enkel linje", name))
            continue
        if not re.search(r"\b" + re.escape(name) + r"\b", cur):
            skipped.append((path, "navnet ikke funnet på linjen", name))
            continue
        count = len(re.findall(r"\b" + re.escape(name) + r"\b", full))
        if not count == 1:
            skipped.append((path, "navnet brukes %d ganger i filen" % count, name))
            continue
        to_delete.add(idx)
    if to_delete:
        plans[path] = [l for i, l in enumerate(lines) if i not in to_delete]
        removed += len(to_delete)

for path, lines in plans.items():
    dest = os.path.join(backup, path)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.copy2(path, dest)
    with open(path, "w", encoding="utf-8") as fh:
        fh.writelines(lines)
    print("Renset: " + path)

print("Fjernet %d ubrukte felt. Backup: %s" % (removed, backup))
if skipped:
    print("Hoppet over (må vurderes manuelt):")
    for path, reason, name in skipped:
        print("  %s %s: %s" % (path, name, reason))
PYEOF

echo ""
echo "Kontroll (kjøres av deg):"
echo "  cd $REPO && flutter analyze"
echo "  Ubrukte felt som ble hoppet over, står over."
