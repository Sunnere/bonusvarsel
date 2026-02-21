#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

if [ ! -f "$FILE" ]; then
  echo "Fant ikke $FILE"
  exit 1
fi

cp -f "$FILE" "$FILE.bak.$(date +%s)"

python - <<'PY'
from pathlib import Path
import re

path = Path("lib/pages/eb_shopping_page.dart")
s = path.read_text(encoding="utf-8")

# 1) Sørg for url_launcher import
if "package:url_launcher/url_launcher.dart" not in s:
  # legg etter flutter/material.dart import hvis mulig
  m = re.search(r"import\s+'package:flutter/material\.dart';\s*\n", s)
  if m:
    insert_at = m.end()
    s = s[:insert_at] + "import 'package:url_launcher/url_launcher.dart';\n" + s[insert_at:]
  else:
    # fallback: øverst
    s = "import 'package:url_launcher/url_launcher.dart';\n" + s

# 2) Legg inn robust _openUrl + _open (alias) inne i _EbShoppingPageState hvis mangler
helper = r"""
  Future<void> _openUrl(String url) async {
    final u = url.trim();
    if (u.isEmpty) return;

    final uri = Uri.tryParse(u);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ugyldig lenke')),
      );
      return;
    }

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke åpne lenken')),
      );
    }
  }

  Future<void> _open(String url) => _openUrl(url);
"""

state_class = re.search(r"class\s+_EbShoppingPageState\s+extends\s+State<[^>]+>\s*\{", s)
if not state_class:
  raise SystemExit("Fant ikke _EbShoppingPageState-klassen. Avbryter for å ikke ødelegge filen.")

# Hvis _openUrl finnes allerede: bare sørg for at _open alias finnes
has_openurl = re.search(r"Future<\s*void\s*>\s*_openUrl\s*\(", s) is not None
has_open = re.search(r"Future<\s*void\s*>\s*_open\s*\(", s) is not None

if has_openurl and not has_open:
  # legg inn bare alias rett etter _openUrl-blokka eller etter klasse-start
  alias = "\n  Future<void> _open(String url) => _openUrl(url);\n"
  m = re.search(r"Future<\s*void\s*>\s*_openUrl\s*\([^\)]*\)\s*async\s*\{[\s\S]*?\n  \}", s)
  if m:
    s = s[:m.end()] + alias + s[m.end():]
  else:
    insert_at = state_class.end()
    s = s[:insert_at] + alias + s[insert_at:]
elif not has_openurl:
  # sett inn helper rett etter klasse-start
  insert_at = state_class.end()
  s = s[:insert_at] + helper + s[insert_at:]

# 3) Bytt eventuelle "launch(...)" / "launchUrl(...)" / "_open(...)" varianter til _openUrl(...)
# (Vi holder dette konservativt: bare sørg for at vanlige onTap/onPressed peker til _openUrl)
s = re.sub(r"onTap:\s*\(\)\s*=>\s*_open\(([^)]+)\)", r"onTap: () => _openUrl(\1)", s)
s = re.sub(r"onPressed:\s*\(\)\s*=>\s*_open\(([^)]+)\)", r"onPressed: () => _openUrl(\1)", s)
s = re.sub(r"onTap:\s*\(\)\s*=>\s*_openUrl\(([^)]+)\)", r"onTap: () => _openUrl(\1)", s)
s = re.sub(r"onPressed:\s*\(\)\s*=>\s*_openUrl\(([^)]+)\)", r"onPressed: () => _openUrl(\1)", s)

path.write_text(s, encoding="utf-8")
print("✅ Patchet open-links i", path)
PY

dart format "$FILE"
flutter analyze

echo "== Restart web =="
kill $(lsof -ti :8080) 2>/dev/null || true
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
