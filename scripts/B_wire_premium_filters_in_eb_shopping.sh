#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[ -f "$FILE" ] || { echo "Finner ikke $FILE"; exit 1; }
cp "$FILE" "$FILE.bak.$(date +%s)"

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")

# 1) Sørg for premium_service import (hvis ikke allerede)
if "premium_service.dart" not in s:
    # legg etter material import om mulig
    s = re.sub(r"(import\s+'package:flutter/material\.dart';\s*\n)",
               r"\1import 'package:bonusvarsel/services/premium_service.dart';\n",
               s, count=1)

# 2) Sørg for premium service instans + premium state-felter
# (vi legger dem kun inn hvis de mangler)
if "_premium = PremiumService()" not in s:
    s = re.sub(r"(class\s+_EbShoppingPageState\s+extends\s+State<[^>]+>\s*{\s*\n)",
               r"\1  final _premium = PremiumService();\n",
               s, count=1)

# premium fields
if "_isPremium" not in s:
    s = re.sub(r"(final\s+Set<String>\s+_fav\s*=\s*<String>{};\s*\n)",
               r"\1  bool _isPremium = false;\n  bool _sortByRate = false;\n  double _minRate = 0;\n",
               s, count=1)

# 3) Sørg for at initState henter premium-status (ikke krasj hvis initState finnes)
if "getIsPremium()" not in s:
    if "void initState()" in s:
        s = re.sub(
            r"(void\s+initState\(\)\s*{\s*\n\s*super\.initState\(\);\s*\n)",
            r"\1    _premium.getIsPremium().then((v) {\n"
            r"      if (!mounted) return;\n"
            r"      setState(() => _isPremium = v);\n"
            r"    });\n",
            s, count=1
        )
    else:
        # legg inn initState rett etter class-start om den mangler
        s = re.sub(
            r"(class\s+_EbShoppingPageState\s+extends\s+State<[^>]+>\s*{\s*\n)",
            r"\1  @override\n"
            r"  void initState() {\n"
            r"    super.initState();\n"
            r"    _premium.getIsPremium().then((v) {\n"
            r"      if (!mounted) return;\n"
            r"      setState(() => _isPremium = v);\n"
            r"    });\n"
            r"  }\n\n",
            s, count=1
        )

# 4) Koble premium-sort/minRate inn i _applyFilters (finn funksjonen og patch trygt)
# Vi forventer en blokk som ender med: return it.toList(); eller tilsvarende.
m = re.search(r"List<\s*Map<String,\s*dynamic>\s*>\s+_applyFilters\([^\)]*\)\s*{", s)
if m:
    # legg inn helper-rate + premium logikk før return (før siste "return" i funksjonen)
    # Vi forsøker å plassere før første "return" i _applyFilters.
    start = m.start()
    # finn slutten av funksjonen ved enkel brace-telling fra start
    i = s.find("{", m.end()-1)
    level = 0
    end = None
    for j in range(i, len(s)):
        if s[j] == "{":
            level += 1
        elif s[j] == "}":
            level -= 1
            if level == 0:
                end = j
                break

    if end:
        body = s[i+1:end]

        if "_minRate" not in body or "_sortByRate" not in body:
            # sett inn premium-blokk før siste return i body
            # finn siste 'return' i body
            rpos = body.rfind("return")
            insert = (
                "\n    // Premium: min poeng + sortering\n"
                "    double _rateOf(Map<String, dynamic> m) {\n"
                "      final v = m['rate'] ?? m['points'] ?? m['poeng'];\n"
                "      if (v is num) return v.toDouble();\n"
                "      return double.tryParse(v?.toString() ?? '') ?? 0.0;\n"
                "    }\n"
                "\n"
                "    if (_isPremium) {\n"
                "      if (_minRate > 0) {\n"
                "        it = it.where((m) => _rateOf(m) >= _minRate);\n"
                "      }\n"
                "      if (_sortByRate) {\n"
                "        final list = it.toList();\n"
                "        list.sort((a, b) => _rateOf(b).compareTo(_rateOf(a)));\n"
                "        it = list;\n"
                "      }\n"
                "    }\n\n"
            )

            if rpos != -1:
                body = body[:rpos] + insert + body[rpos:]
            else:
                body = body + insert

            s = s[:i+1] + body + s[end:]

# 5) Vis premium controls i UI (så feltene er “ekte brukt”)
# Vi legger inn en liten card etter chips/rad hvis vi finner stedet med "Kategori + chips" kommentar.
if "_sortByRate" in s and "Min poeng" not in s:
    s = s.replace(
        "// Kategori + chips",
        "// Kategori + chips\n"
        "                if (_isPremium) ...[\n"
        "                  const SizedBox(height: 10),\n"
        "                  Card(\n"
        "                    child: Padding(\n"
        "                      padding: const EdgeInsets.all(12),\n"
        "                      child: Column(\n"
        "                        crossAxisAlignment: CrossAxisAlignment.start,\n"
        "                        children: [\n"
        "                          SwitchListTile(\n"
        "                            contentPadding: EdgeInsets.zero,\n"
        "                            title: const Text('Sorter på poeng (høyest først)'),\n"
        "                            value: _sortByRate,\n"
        "                            onChanged: (v) => setState(() => _sortByRate = v),\n"
        "                          ),\n"
        "                          const SizedBox(height: 8),\n"
        "                          Text('Min poeng: ${_minRate.toStringAsFixed(0)}'),\n"
        "                          Slider(\n"
        "                            value: _minRate,\n"
        "                            min: 0,\n"
        "                            max: 50,\n"
        "                            divisions: 50,\n"
        "                            label: _minRate.toStringAsFixed(0),\n"
        "                            onChanged: (v) => setState(() => _minRate = v),\n"
        "                          ),\n"
        "                        ],\n"
        "                      ),\n"
        "                    ),\n"
        "                  ),\n"
        "                ],\n"
    )

p.write_text(s, encoding="utf-8")
print("Patchet eb_shopping_page.dart")
PY

dart format "$FILE" >/dev/null
flutter analyze || true
echo "✅ B ferdig: premium-felter er i bruk i eb_shopping_page.dart"
