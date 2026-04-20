#!/usr/bin/env bash
set -euo pipefail

echo "==> 755_dedupe_inputdecoration_args_in_travel_page"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("ERROR: Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_755")
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
]

def find_matching_paren(s: str, open_idx: int) -> int:
    depth = 0
    i = open_idx
    in_single = False
    in_double = False
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

def dedupe_input_decoration_block(block: str) -> str:
    args = split_top_level_args(block)
    seen = set()
    out = []

    for arg in args:
        key = None
        for candidate in TARGET_KEYS:
            prefix = candidate + ":"
            if arg.lstrip().startswith(prefix):
                key = candidate
                break

        if key is None:
            out.append(arg)
            continue

        if key in seen:
            continue

        seen.add(key)
        out.append(arg)

    # pretty formatting
    return ",\n                  ".join(out)

needle = "InputDecoration("
idx = 0
parts = []
last = 0
count = 0

while True:
    start = text.find(needle, idx)
    if start == -1:
        parts.append(text[last:])
        break

    open_idx = start + len("InputDecoration")
    paren_idx = text.find("(", open_idx)
    if paren_idx == -1:
        parts.append(text[last:])
        break

    end_idx = find_matching_paren(text, paren_idx)
    if end_idx == -1:
        parts.append(text[last:])
        break

    inner = text[paren_idx + 1:end_idx]
    fixed_inner = dedupe_input_decoration_block(inner)

    parts.append(text[last:start])
    parts.append("InputDecoration(\n                  " + fixed_inner + "\n                )")

    last = end_idx + 1
    idx = end_idx + 1
    count += 1

new_text = "".join(parts)

if new_text == original:
    print("No changes made.")
else:
    path.write_text(new_text)
    print(f"Patched: {path}")
    print(f"InputDecoration blocks processed: {count}")
PY

echo
echo "✅ 755 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
