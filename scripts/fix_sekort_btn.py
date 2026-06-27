#!/usr/bin/env python3
import os, subprocess

path = os.path.expanduser('~/bonusvarsel/lib/pages/cards_page.dart')
with open(path, 'r') as f:
    lines = f.readlines()

# Finn linje 469 (0-indeksert: 468) og legg til backgroundColor etter foregroundColor
for i, line in enumerate(lines):
    if i >= 467 and i <= 475 and 'foregroundColor: card.activeColor,' in line:
        indent = line[:len(line) - len(line.lstrip())]
        lines.insert(i + 1, f'{indent}backgroundColor: Colors.white,\n')
        print(f"✅ Satt inn backgroundColor: Colors.white etter linje {i+1}")
        break

with open(path, 'w') as f:
    f.writelines(lines)

r = subprocess.run(['grep', '-n', 'backgroundColor: Colors.white', path],
    capture_output=True, text=True)
print(r.stdout)
