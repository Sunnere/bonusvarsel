#!/usr/bin/env bash
set -euo pipefail

echo "==> 757_parse_and_dedupe_all_inputdecorations_in_travel_page"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("ERROR: Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_757")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text

TARGET_KEYS = [
    "filled",
    "fillColor",
    "floatingLabelBehavior",
    "alignLabelWithHint",
    "labelStyle",
    "floatingLabelStyle",
    "contentPadding",
    "border",
    "enabledBorder",
    "focusedBorder",
    "labelText",
    "hintText",
    "prefixIcon",
    "suffixIcon",
    "isDense",
]

def find_matching_paren(s: str, open_idx: int) -> int:
    depth = 0
    in_single = False
    in_double = False
    i = open_idx
    while i < len(s):
        ch = s[i]
        prev = s[i - 1] if i > 0 else ""
        if ch == "'" and not in_double and prev != "\\":
            in_single = not in_single
        elif ch == '"' and not in_single and prev != "\\":
            in_double = not in_double
        elif not in_single and not in_double:
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0:
                    return i
        i += 1
    return -1

def split_top_level_args(s: str):
    args = []
    start = 0
    depth_paren = depth_brack = depth_brace = 0
    in_single = False
    in_double = False

    for i, ch in enumerate(s):
        prev = s[i - 1] if i > 0 else ""
        if ch == "'" and not in_double and prev != "\\":
            in_single = not in_single
        elif ch == '"' and not in_single and prev != "\\":
            in_double = not in_double
        elif not in_single and not in_double:
            if ch == "(":
                depth_paren += 1
            elif ch == ")":
                depth_paren -= 1
            elif ch == "[":
                depth_brack += 1
            elif ch == "]":
                depth_brack -= 1
            elif ch == "{":
                depth_brace += 1
            elif ch == "}":
                depth_brace -= 1
            elif ch == "," and depth_paren == 0 and depth_brack == 0 and depth_brace == 0:
                part = s[start:i].strip()
                if part:
                    args.append(part)
                start = i + 1

    tail = s[start:].strip()
    if tail:
        args.append(tail)
    return args

def dedupe_args(inner: str) -> str:
    args = split_top_level_args(inner)
    seen = set()
    out = []

    for arg in args:
        stripped = arg.lstrip()
        key = None
        for candidate in TARGET_KEYS:
            if stripped.startswith(candidate + ":"):
                key = candidate
                break

        if key is None:
            out.append(arg)
            continue

        if key in seen:
            continue

        seen.add(key)
        out.append(arg)

    return ",\n                  ".join(out)

i = 0
pieces = []
processed = 0

while i < len(text):
    idx_const = text.find("const InputDecoration(", i)
    idx_plain = text.find("InputDecoration(", i)

    candidates = [x for x in [idx_const, idx_plain] if x != -1]
    if not candidates:
        pieces.append(text[i:])
        break

    start = min(candidates)
    pieces.append(text[i:start])

    if text.startswith("const InputDecoration(", start):
        prefix = "const InputDecoration("
        paren_idx = start + len("const InputDecoration")
    else:
        prefix = "InputDecoration("
        paren_idx = start + len("InputDecoration")

    end_idx = find_matching_paren(text, paren_idx)
    if end_idx == -1:
        pieces.append(text[start:])
        break

    inner = text[paren_idx + 1:end_idx]
    rebuilt = "InputDecoration(\n                  " + dedupe_args(inner) + "\n                )"
    pieces.append(rebuilt)

    i = end_idx + 1
    processed += 1

new_text = "".join(pieces)

if new_text == original:
    print("No changes made.")
    raise SystemExit(0)

path.write_text(new_text)
print(f"Patched: {path}")
print(f"InputDecoration-blokker behandlet: {processed}")
PY

echo
echo "✅ 757 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
