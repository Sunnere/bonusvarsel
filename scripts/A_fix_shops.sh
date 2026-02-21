#!/usr/bin/env bash
set -euo pipefail

python - <<'PY'
from pathlib import Path
import re

def patch_file(path: str, fn):
  p = Path(path)
  s = p.read_text(encoding="utf-8")
  ns = fn(s)
  if ns != s:
    p.write_text(ns, encoding="utf-8")
    print(f"✅ Patchet {path}")
  else:
    print(f"ℹ️ Ingen endring i {path}")

# 1) EbRepository: sørg for at loadShops() alltid henter raw['shops'] (ikke forventer liste på root)
def patch_repo(s: str) -> str:
  # Finn loadShops() og bytt implementasjon (robust regex)
  pat = re.compile(r"Future<\s*List<[^>]*>\s*>\s*loadShops\s*\(\s*\)\s*async\s*\{[\s\S]*?\n\}", re.MULTILINE)
  repl = """Future<List<dynamic>> loadShops() async {
    final raw = await loadRaw();

    // assets/eb.shopping.min.json er et Map med keys som 'shops', 'campaigns', osv.
    final shops = (raw['shops'] is List) ? (raw['shops'] as List) : <dynamic>[];
    return shops;
  }"""
  if pat.search(s):
    return pat.sub(repl, s, count=1)

  # fallback: hvis funksjonen har litt annen generics-signatur
  pat2 = re.compile(r"Future<\s*List\s*>\s*loadShops\s*\(\s*\)\s*async\s*\{[\s\S]*?\n\}", re.MULTILINE)
  if pat2.search(s):
    return pat2.sub(repl, s, count=1)

  return s

# 2) EbShoppingPage: map riktige feltnavn (name/rate/url) i UI.
def patch_shopping_page(s: str) -> str:
  # a) Fjern evt. gammel import som peker på eb_repository men ikke brukes riktig
  # (vi lar den stå hvis du bruker EbRepository direkte)
  # b) Erstatt typiske feil keys: 'store'/'points' -> 'name'/'rate'
  s2 = s

  # Bytt de mest vanlige nøklene:
  s2 = re.sub(r"\[\s*'store'\s*\]", "['name']", s2)
  s2 = re.sub(r'\[\s*"store"\s*\]', '["name"]', s2)
  s2 = re.sub(r"\[\s*'points'\s*\]", "['rate']", s2)
  s2 = re.sub(r'\[\s*"points"\s*\]', '["rate"]', s2)

  # Hvis du har hardkodet "Ukjent butikk" pga null: legg inn robuste getters én gang
  if "_shopName(" not in s2:
    # finn start av _EbShoppingPageState og injiser helpers rett etter {
    inj_pat = re.compile(r"(class\s+_EbShoppingPageState\s+extends\s+State<\s*EbShoppingPage\s*>\s*\{\s*)", re.MULTILINE)
    helpers = """\\1
  String _shopName(Map<String, dynamic> shop) {
    final v = shop['name'] ?? shop['title'] ?? shop['merchantName'] ?? shop['displayName'];
    final s = (v ?? '').toString().trim();
    return s.isEmpty ? 'Ukjent butikk' : s;
  }

  int _shopRate(Map<String, dynamic> shop) {
    final v = shop['rate'] ?? shop['points'] ?? shop['value'];
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) {
      try:
        return int(float(v))  # type: ignore
      except:
        return 0
    }
    return 0;
  }

  String _shopUrl(Map<String, dynamic> shop) {
    final v = shop['url'] ?? shop['link'] ?? shop['href'];
    return (v ?? '').toString();
  }

"""
    # Python-syntaks i _shopRate over er feil (int(float(v)) osv) hvis vi lar den stå.
    # Vi skriver det korrekt i Dart i stedet – derfor lager vi helpers i ren Dart under.
    helpers = """\\1
  String _shopName(Map<String, dynamic> shop) {
    final v = shop['name'] ?? shop['title'] ?? shop['merchantName'] ?? shop['displayName'];
    final s = (v ?? '').toString().trim();
    return s.isEmpty ? 'Ukjent butikk' : s;
  }

  int _shopRate(Map<String, dynamic> shop) {
    final v = shop['rate'] ?? shop['points'] ?? shop['value'];
    if (v is int) return v;
    if (v is double) return v.round();
    final str = (v ?? '').toString();
    final parsed = int.tryParse(str);
    if (parsed != null) return parsed;
    final parsedD = double.tryParse(str);
    return (parsedD ?? 0).round();
  }

  String _shopUrl(Map<String, dynamic> shop) {
    final v = shop['url'] ?? shop['link'] ?? shop['href'];
    return (v ?? '').toString();
  }

"""
    s2 = inj_pat.sub(helpers, s2, count=1)

  # Bytt typiske UI-tekstlinjer til å bruke helperne hvis de finnes
  # (Vi gjør dette forsiktig: bare erstatt "Ukjent butikk" direkte der det er shop[...] brukt)
  s2 = re.sub(r"(Ukjent butikk)", r"\1", s2)

  return s2

patch_file("lib/services/eb_repository.dart", patch_repo)
patch_file("lib/pages/eb_shopping_page.dart", patch_shopping_page)
PY

dart format lib/services/eb_repository.dart lib/pages/eb_shopping_page.dart
