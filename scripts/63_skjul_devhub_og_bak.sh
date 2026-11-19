# 63: Skjuler Dev Hub i release-bygg og tar .bak-filer ut av git-indeksen (committer ikke).
#  1) bonusvarsel_dev_hub_page.dart: _devHubEnabled = kDebugMode (var true)
#  2) bonusvarsel_home_api_page.dart: Dev Hub-knappen i AppBar vises bare i debug
#  3) settings_page.dart: 7-trykk på versjonsnummer åpner Dev Hub bare i debug
#  4) git rm --cached på alle sporede .bak-filer, og .gitignore får *.bak[0-9]*
# Filene på disk beholdes. Kjør fra Terminal:
#   bash ~/bonusvarsel/scripts/63_skjul_devhub_og_bak.sh
# Test-miljø: BV_REPO=/sti/til/kopi bash scripts/63_skjul_devhub_og_bak.sh
set -euo pipefail

REPO="${BV_REPO:-$HOME/bonusvarsel}"
cd "$REPO"

TS="$(date +%Y%m%d_%H%M%S)"
BACKUP=".script_backups/63_${TS}"
mkdir -p "$BACKUP"

python3 - "$BACKUP" <<'PYEOF'
import sys, os, shutil
backup = sys.argv[1]

EDITS = {
    "lib/pages/bonusvarsel_dev_hub_page.dart": [
        ("  static const bool _devHubEnabled = true;",
         "  static const bool _devHubEnabled = kDebugMode;"),
    ],
    "lib/pages/bonusvarsel_home_api_page.dart": [
        ("          IconButton(\n            tooltip: 'Dev Hub',",
         "          if (kDebugMode)\n          IconButton(\n            tooltip: 'Dev Hub',"),
    ],
    "lib/pages/settings_page.dart": [
        ("if (_versionTaps >= 7) {",
         "if (kDebugMode && _versionTaps >= 7) {"),
    ],
}

# Pass 1: valider og bygg nytt innhold. Ingenting skrives før alt er OK.
plans = {}
for path, edits in EDITS.items():
    if not os.path.isfile(path):
        raise SystemExit("FEIL: finner ikke %s. Ingen filer er endret." % path)
    with open(path, encoding="utf-8") as fh:
        src = fh.read()
    for old, new in edits:
        if new in src:
            print("Allerede gjort i %s" % path)
            continue
        n = src.count(old)
        if not n == 1:
            raise SystemExit("FEIL: forventet 1 treff i %s, fant %d. Ingen filer er endret." % (path, n))
        src = src.replace(old, new, 1)
    plans[path] = src

# Pass 2: backup og skriv
for path, src in plans.items():
    dest = os.path.join(backup, path)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.copy2(path, dest)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(src)
    print("Endret: " + path)
PYEOF

# .gitignore: fang opp .bak28, .bak29 osv.
if grep -qxF '*.bak[0-9]*' .gitignore 2>/dev/null; then
  echo ".gitignore har allerede *.bak[0-9]*"
else
  cp .gitignore "$BACKUP/.gitignore" 2>/dev/null || true
  printf '\n# Nummererte backupfiler (bak28, bak29 ...)\n*.bak[0-9]*\n' >> .gitignore
  echo ".gitignore: la til *.bak[0-9]*"
fi

# Ta sporede .bak-filer ut av indeksen (filene på disk beholdes)
if git rev-parse --git-dir >/dev/null 2>&1; then
  COUNT=0
  while IFS= read -r f; do
    git rm --cached -q -- "$f"
    COUNT=$((COUNT + 1))
  done < <(git ls-files | grep -E '\.bak' || true)
  echo "Fjernet $COUNT .bak-filer fra git-indeksen (ikke committet)"
else
  echo "Ikke et git-repo: hoppet over git rm"
fi

echo ""
echo "Neste steg (kjøres av deg):"
echo "  cd $REPO && flutter analyze"
echo "  Bygg 1.3.4+42 slik at Dev Hub-fiksen kommer ut til brukerne"
echo "  git status   (se over endringene, commit når du er klar)"
