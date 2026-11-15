# 56: Fjerner kun ubrukte imports og duplikate imports, rapportert av flutter analyze.
# Ingen annen kode endres. Kjør fra Terminal:
#   bash ~/bonusvarsel/scripts/56_lint_imports.sh
# Test-miljø: BV_REPO=/sti/til/kopi FLUTTER_BIN=/sti/til/fake-flutter bash scripts/56_lint_imports.sh
set -euo pipefail

REPO="${BV_REPO:-$HOME/bonusvarsel}"
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
cd "$REPO"

TS="$(date +%Y%m%d_%H%M%S)"
BACKUP=".script_backups/56_${TS}"
mkdir -p "$BACKUP"

# Vanlig tekstutdata fra flutter analyze (--machine støttes ikke i denne Flutter-versjonen)
"$FLUTTER_BIN" analyze --no-pub > "$BACKUP/analyze.txt" 2>/dev/null || true

python3 - "$BACKUP" <<'PYEOF'
import sys, os, re, shutil
backup = sys.argv[1]
with open(os.path.join(backup, "analyze.txt"), encoding="utf-8", errors="replace") as fh:
    text = fh.read()

# Slå sammen linjer som er brutt over flere linjer (fortsettelser starter med mange mellomrom)
text = re.sub(r"\n\s{4,}", " ", text)
records = re.split(r"\n(?=\s*(?:error|warning|info) •)", text)

targets = {}
for rec in records:
    rec = " ".join(rec.split())
    if not re.search(r"\b(unused_import|duplicate_import)\b\s*$", rec):
        continue
    m = re.search(r"(lib/[^\s:]+\.dart|test/[^\s:]+\.dart|bin/[^\s:]+\.dart):(\d+):(\d+)", rec)
    if not m:
        continue
    path, line = m.group(1), int(m.group(2))
    targets.setdefault(path, set()).add(line)

if not targets:
    print("Ingen ubrukte eller duplikate imports funnet.")
    raise SystemExit(0)

# Pass 1: valider alt og bygg nytt innhold i minnet. Ingenting skrives før alt er OK.
plans = {}
total = 0
for path in sorted(targets):
    if not os.path.isfile(path):
        print("HOPPER OVER (finnes ikke): " + path)
        continue
    with open(path, encoding="utf-8") as fh:
        lines = fh.readlines()
    for n in sorted(targets[path], reverse=True):
        idx = n - 1
        if idx < 0 or idx >= len(lines):
            raise SystemExit("FEIL: linje %d finnes ikke i %s. Ingen filer er endret." % (n, path))
        if not lines[idx].lstrip().startswith("import "):
            raise SystemExit("FEIL: linje %d i %s er ikke en import. Ingen filer er endret." % (n, path))
        del lines[idx]
        total += 1
    plans[path] = lines

# Pass 2: backup og skriv
for path, lines in plans.items():
    dest = os.path.join(backup, path)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.copy2(path, dest)
    with open(path, "w", encoding="utf-8") as fh:
        fh.writelines(lines)
    print("Renset: " + path + " (" + str(len(targets[path])) + " import)")
print("Totalt fjernet: %d import. Backup: %s" % (total, backup))
PYEOF

echo ""
echo "Kontroll (kjøres av deg):"
echo "  cd $REPO && flutter analyze"
echo "  Forventet: ingen flere unused_import- eller duplicate_import-meldinger."
