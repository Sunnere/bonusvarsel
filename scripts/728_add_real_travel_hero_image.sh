#!/usr/bin/env bash
set -euo pipefail

echo "==> 728_add_real_travel_hero_image"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_728")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()

# Ensure assets import
if "import 'package:flutter/material.dart';" in text:
    pass

# Inject hero image container
hero = """
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/travel_hero.jpg',
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xAA000000),
                            Color(0x44000000),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '✈️ Planlegg reisen smartere',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Se hva du mangler av poeng før du bestiller',
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
"""

# Inject after first children:
text = text.replace(
    "children: [",
    "children: [\n" + hero,
    1
)

path.write_text(text)
print("Hero image added")
PY

echo
echo "✅ 728 ferdig"
echo
echo "HUSK:"
echo "1. Legg bilde i assets/images/travel_hero.jpg"
echo "2. Legg til i pubspec.yaml:"
echo "   assets:"
echo "     - assets/images/travel_hero.jpg"
echo
echo "Kjør:"
echo "flutter run -d macos"
