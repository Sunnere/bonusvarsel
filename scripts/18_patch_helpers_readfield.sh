#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

if [[ ! -f "$FILE" ]]; then
  echo "Fant ikke $FILE"
  exit 1
fi

cp "$FILE" "$FILE.bak.$(date +%s)"

python3 - "$FILE" <<'PY'
import re, sys, pathlib
path = pathlib.Path(sys.argv[1])
s = path.read_text(encoding="utf-8")

readfield = r"""
  T? _readField<T>(Object it, String key1, [String? key2]) {
    if (it is Map<String, dynamic>) {
      final v1 = it[key1];
      if (v1 != null) return v1 as T;
      if (key2 != null) {
        final v2 = it[key2];
        if (v2 != null) return v2 as T;
      }
      return null;
    }

    // Fallback for modell-objekter (ShopOffer etc.)
    try {
      final d = it as dynamic;
      final v1 = d[key1];
      if (v1 != null) return v1 as T;
      if (key2 != null) {
        final v2 = d[key2];
        if (v2 != null) return v2 as T;
      }
    } catch (_) {
      // ignore
    }
    return null;
  }
""".strip("\n")

category_fn = r"""
  String _categoryOf(Object it) {
    final v = _readField(it, 'category', 'kategori');
    return (v ?? 'Ukjent').toString();
  }
""".strip("\n")

campaign_fn = r"""
  bool _isCampaignOf(Object it) {
    final v = _readField(it, 'isCampaign', 'campaign');
    return (v ?? false) == true;
  }
""".strip("\n")

# 1) Replace existing _categoryOf(...) { ... }
s2, n1 = re.subn(
    r"\n\s*String\s+_categoryOf\s*\(\s*Object\s+\w+\s*\)\s*\{.*?\n\s*\}\s*\n",
    "\n\n" + category_fn + "\n\n",
    s,
    flags=re.S,
)

# 2) Replace existing _isCampaignOf(...) { ... }
s3, n2 = re.subn(
    r"\n\s*bool\s+_isCampaignOf\s*\(\s*Object\s+\w+\s*\)\s*\{.*?\n\s*\}\s*\n",
    "\n\n" + campaign_fn + "\n\n",
    s2,
    flags=re.S,
)

# 3) Ensure _readField exists (insert above the first of the two helpers if missing)
if "_readField<T>(" not in s3:
    # Insert right before _categoryOf if present, else before _isCampaignOf, else after class header
    m = re.search(r"\n\s*String\s+_categoryOf\s*\(", s3)
    if not m:
        m = re.search(r"\n\s*bool\s+_isCampaignOf\s*\(", s3)
    if m:
        idx = m.start()
        s3 = s3[:idx] + "\n\n" + readfield + "\n\n" + s3[idx:]
    else:
        # fallback: put after class declaration line
        m = re.search(r"class\s+_EbShoppingPageState[^{]*\{", s3)
        if not m:
            raise SystemExit("Fant ikke klassen _EbShoppingPageState å sette inn helper.")
        idx = m.end()
        s3 = s3[:idx] + "\n\n" + readfield + "\n\n" + s3[idx:]

path.write_text(s3, encoding="utf-8")
print(f"✅ Patchet helpers: _readField + _categoryOf + _isCampaignOf (replaced {n1} + {n2})")
PY

dart format "$FILE" >/dev/null || true
flutter analyze || true
