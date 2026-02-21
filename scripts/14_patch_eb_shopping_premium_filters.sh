#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[ -f "$FILE" ] || { echo "Fant ikke $FILE"; exit 1; }
cp "$FILE" "$FILE.bak.$(date +%s)"

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")

# imports
if "dart:async" not in s:
    s = s.replace("import 'dart:convert';", "import 'dart:async';\nimport 'dart:convert';")

if "premium_service.dart" not in s:
    # prøv å sette sammen med andre imports
    s = s.replace(
        "import 'package:url_launcher/url_launcher.dart';",
        "import 'package:url_launcher/url_launcher.dart';\nimport 'package:bonusvarsel/services/premium_service.dart';"
    )

# state fields: sett inn etter _favFirst / _fav
needle = "bool _favFirst = false;"
if needle in s and "_isPremium" not in s:
    s = s.replace(
        needle,
        needle
        + "\n  bool _isPremium = false;"
        + "\n  bool _sortByRate = false;"
        + "\n  double _minRate = 0;"
        + "\n  final _premium = const PremiumService();"
    )

# initState: last premium og prefs
if "void initState()" in s and "_premium.getIsPremium" not in s:
    s = re.sub(
        r"(void initState\(\)\s*\{\s*\n\s*super\.initState\(\);\s*\n)",
        r"\1"
        r"    _premium.getIsPremium().then((v) {\n"
        r"      if (!mounted) return;\n"
        r"      setState(() => _isPremium = v);\n"
        r"    });\n",
        s,
        count=1
    )

# applyFilters: legg på minRate og sortByRate (på Map-lista)
# vi finner slutten av funksjonen ved "return it.toList();" / "return out;" etc.
if "_applyFilters" in s and "_minRate" in s and "minRate" not in s:
    # Sett inn rett før return it.toList();
    s = s.replace(
        "return it.toList();",
        "    if (_isPremium && _minRate > 0) {\n"
        "      it = it.where((s) {\n"
        "        final r = (s['rate'] ?? s['points'] ?? s['poeng'] ?? 0);\n"
        "        final num rr = (r is num) ? r : (num.tryParse(r.toString()) ?? 0);\n"
        "        return rr >= _minRate;\n"
        "      });\n"
        "    }\n"
        "\n"
        "    var list = it.toList();\n"
        "    if (_isPremium && _sortByRate) {\n"
        "      num rateOf(Map<String, dynamic> s) {\n"
        "        final r = (s['rate'] ?? s['points'] ?? s['poeng'] ?? 0);\n"
        "        return (r is num) ? r : (num.tryParse(r.toString()) ?? 0);\n"
        "      }\n"
        "      list.sort((a, b) => rateOf(b).compareTo(rateOf(a)));\n"
        "    }\n"
        "    return list;",
    )

# UI: legg inn premium controls nær chips (vi ser etter FilterChip for _favFirst)
if "FilterChip" in s and "_favFirst" in s and "Minimum poeng" not in s:
    s = s.replace(
        "FilterChip(",
        "FilterChip(",
    )
    # Sett inn etter fav-first chip-blokka ved å finne andre chip label (Favoritter først)
    s = re.sub(
        r"(label:\s*const\s*Text\('Favoritter først'\)[\s\S]*?\)\s*,)",
        r"\1\n\n            if (_isPremium) ...[\n"
        r"              const SizedBox(width: 10),\n"
        r"              FilterChip(\n"
        r"                selected: _sortByRate,\n"
        r"                label: const Text('Høyeste poeng først'),\n"
        r"                onSelected: (v) => setState(() => _sortByRate = v),\n"
        r"              ),\n"
        r"            ],",
        s,
        count=1
    )

    # Legg inn slider under chips-raden: finn første "const SizedBox(height:" etter chips og sett inn
    s = re.sub(
        r"(// Kategori \+ chips[\s\S]*?children:\s*\[[\s\S]*?\]\s*\)\s*,)",
        r"\1\n\n          if (_isPremium) Padding(\n"
        r"            padding: const EdgeInsets.symmetric(horizontal: 16),\n"
        r"            child: Column(\n"
        r"              crossAxisAlignment: CrossAxisAlignment.start,\n"
        r"              children: [\n"
        r"                const SizedBox(height: 8),\n"
        r"                Text('Minimum poeng: ${_minRate.toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodyMedium),\n"
        r"                Slider(\n"
        r"                  value: _minRate,\n"
        r"                  min: 0,\n"
        r"                  max: 50,\n"
        r"                  divisions: 50,\n"
        r"                  label: _minRate.toStringAsFixed(0),\n"
        r"                  onChanged: (v) => setState(() => _minRate = v),\n"
        r"                ),\n"
        r"              ],\n"
        r"            ),\n"
        r"          ),",
        s,
        count=1
    )

p.write_text(s, encoding="utf-8")
print("Patchet eb_shopping_page.dart (premium filters + sort)")
PY

dart format "$FILE"
flutter analyze
