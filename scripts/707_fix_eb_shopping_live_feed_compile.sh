#!/usr/bin/env bash
set -euo pipefail

echo "==> 707_fix_eb_shopping_live_feed_compile"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re
import os

PAGE = Path("lib/pages/eb_shopping_page.dart")
if not PAGE.exists():
    print("ERROR: lib/pages/eb_shopping_page.dart not found")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = PAGE.with_name(PAGE.name + f".bak_{stamp}_707")
shutil.copy2(PAGE, bak)
print(f"Backup: {bak}")

text = PAGE.read_text()

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

def ensure_import(src: str, import_line: str) -> str:
    if import_line in src:
        return src
    imports = list(re.finditer(r"^import\s+['\"].*?['\"];\s*$", src, flags=re.MULTILINE))
    if imports:
        last = imports[-1]
        insert_at = last.end()
        return src[:insert_at] + "\n" + import_line + src[insert_at:]
    return import_line + "\n" + src

def remove_line_containing(src: str, needle: str) -> str:
    lines = src.splitlines()
    lines = [ln for ln in lines if needle not in ln]
    return "\n".join(lines) + ("\n" if src.endswith("\n") else "")

def has_field(src: str) -> bool:
    return "_offersDataSource" in src and "EbShoppingOffersDataSource" in src

def relative_import(from_file: Path, target_file: Path) -> str:
    rel = os.path.relpath(target_file, from_file.parent).replace(os.sep, "/")
    return rel

# ------------------------------------------------------------
# Find repository path if it exists
# ------------------------------------------------------------

repo_file = None
for p in Path("lib").rglob("*.dart"):
    try:
        body = p.read_text()
    except Exception:
        continue
    if re.search(r"\bclass\s+OffersFeedRepository\b", body):
        repo_file = p
        break

repo_import_line = None
repo_ctor = "OffersFeedRepository()"

if repo_file is not None:
    rel = relative_import(PAGE, repo_file)
    repo_import_line = f"import '{rel}';"
    print(f"Found OffersFeedRepository: {repo_file}")
else:
    print("OffersFeedRepository not found. Will inject local noop repository.")

# ------------------------------------------------------------
# Ensure imports for datasource/vm
# ------------------------------------------------------------

text = ensure_import(text, "import '../features/offers/eb_shopping_offers_datasource.dart';")
text = ensure_import(text, "import '../features/offers/eb_shopping_offer_vm.dart';")
if repo_import_line:
    text = ensure_import(text, repo_import_line)

# ------------------------------------------------------------
# Inject _offersDataSource field inside state class if missing
# ------------------------------------------------------------

state_pattern = re.compile(
    r"(class\s+_EbShoppingPageState\s+extends\s+State<\s*EbShoppingPage\s*>\s*{)",
    flags=re.MULTILINE,
)

if "_offersDataSource" not in text:
    m = state_pattern.search(text)
    if m:
        inject = (
            m.group(1)
            + "\n"
            + "  late final EbShoppingOffersDataSource _offersDataSource;\n"
        )
        text = text[:m.start()] + inject + text[m.end():]
        print("Inserted _offersDataSource field.")
    else:
        print("WARNING: Could not find _EbShoppingPageState class header to inject field.")

# ------------------------------------------------------------
# Remove broken legacy fallback line
# ------------------------------------------------------------

text = remove_line_containing(text, "legacyFallbackLoader: _loadLegacyEbShoppingOffers")

# ------------------------------------------------------------
# Fix / insert initState assignment
# ------------------------------------------------------------

assignment_block = (
    "    _offersDataSource = EbShoppingOffersDataSource(\n"
    f"      offersFeedRepository: {repo_ctor},\n"
    "    );\n"
)

# If initState exists, ensure assignment is inside it.
init_pattern = re.compile(
    r"(@override\s+void\s+initState\(\)\s*{\s*super\.initState\(\);\s*)",
    flags=re.MULTILINE,
)

if "_offersDataSource =" not in text:
    m = init_pattern.search(text)
    if m:
        text = text[:m.end()] + assignment_block + text[m.end():]
        print("Inserted _offersDataSource assignment into initState().")
    else:
        # fallback: add initState inside state class
        m = state_pattern.search(text)
        if m:
            insert = (
                "\n"
                "  @override\n"
                "  void initState() {\n"
                "    super.initState();\n"
                + assignment_block +
                "  }\n"
            )
            text = text[:m.end()] + insert + text[m.end():]
            print("Created initState() with _offersDataSource assignment.")
        else:
            print("WARNING: Could not inject initState().")

# If a broken assignment block exists, normalize it.
text = re.sub(
    r"_offersDataSource\s*=\s*EbShoppingOffersDataSource\s*\((?:.|\n)*?\);\s*",
    "_offersDataSource = EbShoppingOffersDataSource(\n"
    f"      offersFeedRepository: {repo_ctor},\n"
    "    );\n",
    text,
    count=1,
)

# ------------------------------------------------------------
# Ensure loader method exists and is valid
# ------------------------------------------------------------

if "Future<List<EbShoppingOfferVm>> _loadLiveOrFallbackOffers()" not in text:
    last_brace = text.rfind("}")
    method = (
        "\n"
        "  Future<List<EbShoppingOfferVm>> _loadLiveOrFallbackOffers() async {\n"
        "    return _offersDataSource.load();\n"
        "  }\n"
    )
    text = text[:last_brace] + method + "\n" + text[last_brace:]
    print("Inserted _loadLiveOrFallbackOffers().")
else:
    text = re.sub(
        r"Future<List<EbShoppingOfferVm>>\s+_loadLiveOrFallbackOffers\(\)\s+async\s*{(?:.|\n)*?}",
        "Future<List<EbShoppingOfferVm>> _loadLiveOrFallbackOffers() async {\n"
        "    return _offersDataSource.load();\n"
        "  }",
        text,
        count=1,
    )
    print("Normalized _loadLiveOrFallbackOffers().")

# ------------------------------------------------------------
# If repo not found, inject local noop repo near bottom of file
# ------------------------------------------------------------

if repo_file is None and "_NoopOffersFeedRepository" not in text:
    # Also replace OffersFeedRepository() with _NoopOffersFeedRepository()
    text = text.replace("OffersFeedRepository()", "_NoopOffersFeedRepository()")
    last_brace = text.rfind("}")
    stub = """

class _NoopOffersFeedRepository {
  Future<_NoopOffersFeedResponse> fetchOffersFeed() async {
    return const _NoopOffersFeedResponse();
  }
}

class _NoopOffersFeedResponse {
  const _NoopOffersFeedResponse();

  List<dynamic> get items => const <dynamic>[];
}
"""
    text = text[:last_brace] + stub + "\n" + text[last_brace:]
    print("Injected _NoopOffersFeedRepository fallback.")
else:
    text = text.replace("_NoopOffersFeedRepository()", "OffersFeedRepository()")

# ------------------------------------------------------------
# Clean up any duplicate empty lines from removals
# ------------------------------------------------------------

text = re.sub(r"\n{3,}", "\n\n", text)

PAGE.write_text(text)
print(f"Patched: {PAGE}")
PY

echo
echo "✅ 707 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run"
