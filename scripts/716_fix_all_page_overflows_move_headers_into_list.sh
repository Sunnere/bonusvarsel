#!/usr/bin/env bash
set -euo pipefail

echo "==> 716_fix_all_page_overflows_move_headers_into_list"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

pages_dir = Path("lib/pages")
if not pages_dir.exists():
    print("ERROR: lib/pages not found")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
changed = []

def find_matching_paren(text: str, open_paren_idx: int):
    i = open_paren_idx
    depth = 0
    in_single = False
    in_double = False
    in_triple_single = False
    in_triple_double = False
    escape = False

    while i < len(text):
        ch = text[i]

        if escape:
            escape = False
            i += 1
            continue

        if ch == "\\" and (in_single or in_double or in_triple_single or in_triple_double):
            escape = True
            i += 1
            continue

        if not in_double and not in_triple_single and not in_triple_double and text[i:i+3] == "'''":
            in_triple_single = not in_triple_single
            i += 3
            continue

        if not in_single and not in_triple_single and not in_triple_double and text[i:i+3] == '"""':
            in_triple_double = not in_triple_double
            i += 3
            continue

        if not in_triple_single and not in_triple_double:
            if ch == "'" and not in_double:
                in_single = not in_single
                i += 1
                continue
            if ch == '"' and not in_single:
                in_double = not in_double
                i += 1
                continue

        if in_single or in_double or in_triple_single or in_triple_double:
            i += 1
            continue

        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return i

        i += 1

    return None

def patch_file(path: Path) -> bool:
    text = path.read_text()
    original = text

    body_idx = text.find("body: Column(")
    if body_idx == -1:
        return False

    children_idx = text.find("children: [", body_idx)
    if children_idx == -1:
        return False

    expanded_idx = text.find("Expanded(", children_idx)
    if expanded_idx == -1:
        return False

    top_chunk = text[children_idx + len("children: ["):expanded_idx]
    if top_chunk.strip() == "":
        return False

    # Skip obviously tiny top chunks
    marker_count = 0
    markers = [
        "Header",
        "Card(",
        "_build",
        "Padding(",
        "SizedBox(",
        "Text(",
        "Filter",
        "Recommendation",
    ]
    for m in markers:
        if m in top_chunk:
            marker_count += 1
    if marker_count < 2:
        return False

    search_window = text[expanded_idx:expanded_idx + 30000]
    rel = search_window.find("ListView(")
    if rel == -1:
        rel = search_window.find("return ListView(")
    if rel == -1:
        return False

    list_idx = expanded_idx + rel
    list_children_idx = text.find("children: [", list_idx)
    if list_children_idx == -1:
        return False

    # Avoid double insert
    existing_after = text[list_children_idx:list_children_idx + 2500]
    overlap_markers = 0
    for m in ["_PremiumHeader(", "SmartBestRecommendationCard(", "_buildSourceFilter(", "Toppbutikker", "Travel", "Reis", "Trip"]:
        if m in top_chunk and m in existing_after:
            overlap_markers += 1
    if overlap_markers >= 2:
        return False

    # Insert top chunk into ListView children
    insert_at = list_children_idx + len("children: [")
    text = text[:insert_at] + "\n" + top_chunk.rstrip() + "\n" + text[insert_at:]

    # Remove top chunk from outer Column so only Expanded remains there
    text = text[:children_idx + len("children: [")] + "\n          " + text[expanded_idx:]

    # Clean up
    text = re.sub(r"\n{3,}", "\n\n", text)

    if text == original:
        return False

    bak = path.with_name(path.name + f".bak_{stamp}_716")
    shutil.copy2(path, bak)
    path.write_text(text)
    print(f"Patched: {path}")
    print(f"Backup : {bak}")
    return True

for path in sorted(pages_dir.rglob("*.dart")):
    try:
        if patch_file(path):
            changed.append(str(path))
    except Exception as e:
        print(f"SKIP {path}: {e}")

print()
if changed:
    print("Changed files:")
    for p in changed:
        print(f" - {p}")
else:
    print("No matching pages were changed.")
PY

echo
echo "✅ 716 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
