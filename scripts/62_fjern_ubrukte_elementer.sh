# 62: Fjerner ubrukte private elementer (unused_element): metoder, getters og klasser.
# Et element fjernes kun når:
#   - navnet bare forekommer i selve blokken (ingen andre referanser i filen);
#   - klammer og parenteser i deklarasjonen balanserer, så blokken kan avgrenses.
# Doc-kommentarer og annotasjoner rett over deklarasjonen fjernes sammen med den.
# Etter endringen kjøres flutter analyze på nytt. Blir det flere feil enn før, gjenopprettes alle filer.
# Kjør fra Terminal:
#   bash ~/bonusvarsel/scripts/62_fjern_ubrukte_elementer.sh
# Test-miljø: BV_REPO=/sti/til/kopi FLUTTER_BIN=/sti/til/fake-flutter bash scripts/62_fjern_ubrukte_elementer.sh
set -euo pipefail

REPO="${BV_REPO:-$HOME/bonusvarsel}"
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
cd "$REPO"

TS="$(date +%Y%m%d_%H%M%S)"
BACKUP=".script_backups/62_${TS}"
mkdir -p "$BACKUP"

"$FLUTTER_BIN" analyze --no-pub > "$BACKUP/analyze.txt" 2>/dev/null || true
FEIL_FOR="$(grep -c "error •" "$BACKUP/analyze.txt" || true)"

python3 - "$BACKUP" <<'PYEOF'
import sys, os, re, shutil
backup = sys.argv[1]
with open(os.path.join(backup, "analyze.txt"), encoding="utf-8", errors="replace") as fh:
    text = fh.read()

text = re.sub(r"\n\s{4,}", " ", text)
records = re.split(r"\n(?=\s*(?:error|warning|info) •)", text)

targets = {}  # path -> list of (line, name)
for rec in records:
    rec = " ".join(rec.split())
    if not re.search(r"\bunused_element\b(\s+\d+ issues? found\..*)?\s*$", rec):
        continue
    m_loc = re.search(r"(lib/[^\s:]+\.dart):(\d+):(\d+)", rec)
    m_name = re.search(r"declaration '(\w+)'", rec)
    if not m_loc or not m_name:
        continue
    targets.setdefault(m_loc.group(1), []).append((int(m_loc.group(2)), m_name.group(1)))

if not targets:
    print("Ingen ubrukte private elementer funnet.")
    raise SystemExit(0)

def naive_balance(line):
    """Netto klammerbalanse på linjen, med strenger og kommentarer hoppet over."""
    depth = 0
    in_str = None
    k = 0
    while k < len(line):
        ch = line[k]
        if in_str:
            if ch == "\\":
                k += 2
                continue
            if ch == in_str:
                in_str = None
        else:
            if line[k:k+2] == "//":
                break
            if ch in "'\"":
                in_str = ch
            elif ch in "([{":
                depth += 1
            elif ch in ")]}":
                depth -= 1
        k += 1
    return depth

def find_block_end(lines, start):
    """Returnerer indeksen til siste linje i deklarasjonen, eller None."""
    depth = 0
    seen_open = False
    for j in range(start, len(lines)):
        line = lines[j]
        bal = naive_balance(line)
        if bal > 0:
            seen_open = True
        depth += bal
        s = line.strip()
        if depth == 0 and (s.endswith(";") or s.endswith("}")):
            return j
        if depth < 0:
            return None
    return None

plans = {}
skipped = []
removed = 0
changed = []

for path in sorted(targets):
    if not os.path.isfile(path):
        skipped.append((path, "fil finnes ikke", ""))
        continue
    with open(path, encoding="utf-8") as fh:
        lines = fh.readlines()
    full = "".join(lines)
    to_delete = set()
    for line_no, name in sorted(targets[path], reverse=True):
        idx = line_no - 1
        if idx < 0 or idx >= len(lines):
            skipped.append((path, "linje finnes ikke", name))
            continue
        pattern = r"\b" + re.escape(name) + r"\b"
        if not re.search(pattern, lines[idx]):
            skipped.append((path, "navnet ikke funnet på linjen", name))
            continue
        if idx in to_delete:
            continue
        end = find_block_end(lines, idx)
        if end is None:
            skipped.append((path, "blokken kan ikke avgrenses trygt", name))
            continue
        start = idx
        while start > 0 and lines[start - 1].strip().startswith(("//", "@")):
            start -= 1
        block_count = sum(len(re.findall(pattern, lines[i])) for i in range(start, end + 1))
        full_count = len(re.findall(pattern, full))
        if not full_count == block_count:
            skipped.append((path, "navnet brukes andre steder i filen", name))
            continue
        stop = end
        if stop + 1 < len(lines) and lines[stop + 1].strip() == "" and (start == 0 or lines[start - 1].strip() == ""):
            stop += 1
        for i in range(start, stop + 1):
            to_delete.add(i)
        removed += 1
    if to_delete:
        plans[path] = [l for i, l in enumerate(lines) if i not in to_delete]

for path, lines in plans.items():
    dest = os.path.join(backup, path)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.copy2(path, dest)
    with open(path, "w", encoding="utf-8") as fh:
        fh.writelines(lines)
    changed.append(path)
    print("Renset: " + path)

with open(os.path.join(backup, "changed.txt"), "w", encoding="utf-8") as fh:
    fh.write("\n".join(changed) + ("\n" if changed else ""))

print("Fjernet %d ubrukte elementer. Backup: %s" % (removed, backup))
if skipped:
    print("Hoppet over (må vurderes manuelt):")
    for path, reason, name in skipped:
        print("  %s %s: %s" % (path, name, reason))
PYEOF

if [ -s "$BACKUP/changed.txt" ]; then
  "$FLUTTER_BIN" analyze --no-pub > "$BACKUP/analyze_etter.txt" 2>/dev/null || true
  FEIL_ETTER="$(grep -c "error •" "$BACKUP/analyze_etter.txt" || true)"
  if [ "$FEIL_ETTER" -gt "$FEIL_FOR" ]; then
    while IFS= read -r f; do
      cp "$BACKUP/$f" "$f"
    done < "$BACKUP/changed.txt"
    echo "FEIL: flere analysefeil etter endring ($FEIL_FOR -> $FEIL_ETTER). Alle filer er gjenopprettet."
    exit 1
  fi
  echo "Analysefeil før: $FEIL_FOR, etter: $FEIL_ETTER. OK."
fi

echo ""
echo "Kontroll (kjøres av deg):"
echo "  cd $REPO && flutter analyze"
echo "  Ubrukte elementer som ble hoppet over, står over."
