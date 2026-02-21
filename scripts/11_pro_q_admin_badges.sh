#!/usr/bin/env bash
set -euo pipefail

PAGE="lib/pages/eb_shopping_page.dart"
PREM="lib/services/premium_service.dart"

[ -f "$PAGE" ] || { echo "Fant ikke $PAGE"; exit 1; }
[ -f "$PREM" ] || { echo "Fant ikke $PREM"; exit 1; }

cp "$PAGE" "$PAGE.bak.$(date +%s)" || true
cp "$PREM" "$PREM.bak.$(date +%s)" || true

python - <<'PY'
from pathlib import Path
import re

page = Path("lib/pages/eb_shopping_page.dart")
prem = Path("lib/services/premium_service.dart")

# ---------------------------
# 1) PremiumService: admin prefs (show badges + free limit)
# ---------------------------
s = prem.read_text(encoding="utf-8")

# Ensure keys + helpers exist (idempotent)
if "_kShowBadges" not in s:
    # Try to insert near existing key(s), else top of class
    # Find class PremiumService { ... }
    m = re.search(r"(class\s+PremiumService\s*\{)", s)
    if not m:
        raise SystemExit("Fant ikke class PremiumService i premium_service.dart")

    insert = r"""
  static const String _kIsPremium = 'isPremium';
  static const String _kShowBadges = 'admin_showBadges';
  static const String _kFreeLimit = 'admin_freeLimit';

  Future<bool> getShowBadges() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowBadges) ?? true;
  }

  Future<void> setShowBadges(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowBadges, v);
  }

  Future<int> getFreeLimit({int fallback = 30}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kFreeLimit) ?? fallback;
  }

  Future<void> setFreeLimit(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kFreeLimit, v);
  }
""".rstrip("\n") + "\n"

    # If _kIsPremium already exists, don't duplicate it. Remove that line if present elsewhere.
    if "_kIsPremium" in s:
        insert = re.sub(r"^\s*static const String _kIsPremium.*\n", "", insert, flags=re.M)

    s = s[:m.end()] + "\n" + insert + s[m.end():]

# Ensure getIsPremium exists (some earlier scripts used getIsPremium())
if "Future<bool> getIsPremium()" not in s:
    # If there is isPremium() method, we don't force; we add a compatible method wrapper.
    if "isPremium(" in s:
        # add wrapper method inside class
        m = re.search(r"(class\s+PremiumService\s*\{)", s)
        insert = """
  Future<bool> getIsPremium() async {
    return isPremium();
  }
""".rstrip("\n") + "\n"
        s = s[:m.end()] + "\n" + insert + s[m.end():]
    else:
        # create standard getter (expects SharedPreferences import exists already)
        m = re.search(r"(class\s+PremiumService\s*\{)", s)
        insert = """
  Future<bool> getIsPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsPremium) ?? false;
  }

  Future<void> setIsPremium(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsPremium, v);
  }
""".rstrip("\n") + "\n"
        s = s[:m.end()] + "\n" + insert + s[m.end():]

prem.write_text(s, encoding="utf-8")

# ---------------------------
# 2) eb_shopping_page.dart: debug-only admin dialog + showBadges + freeLimit
# ---------------------------
p = page.read_text(encoding="utf-8")

# Ensure import for kDebugMode
if "package:flutter/foundation.dart" not in p:
    # add after material import if possible
    p = re.sub(r"(import\s+'package:flutter/material\.dart';\s*)",
               r"\1\nimport 'package:flutter/foundation.dart' show kDebugMode;\n",
               p, count=1)

# Ensure we have _premiumSvc field name used (seen in your file)
# Add state fields if missing
if "_showBadges" not in p:
    # Insert near premiumSvc field
    m = re.search(r"(PremiumService\s+_premiumSvc\s*=\s*const\s+PremiumService\(\)\s*;|PremiumService\s+_premiumSvc\s*=\s*PremiumService\(\)\s*;)", p)
    if m:
        insert = """
  bool _showBadges = true;
  int _freeLimit = 30;
""".rstrip("\n") + "\n"
        p = p[:m.end()] + "\n" + insert + p[m.end():]

# Replace static const freeLimit if present
p = re.sub(r"static\s+const\s+int\s+freeLimit\s*=\s*\d+\s*;\s*\n", "", p)

# In initState: load admin prefs (showBadges/freeLimit) once
if "getShowBadges" not in p or "getFreeLimit" not in p:
    # find initState block
    if "void initState()" in p:
        if "_premiumSvc.getShowBadges" not in p:
            p = re.sub(
                r"(void\s+initState\(\)\s*\{\s*\n\s*super\.initState\(\)\s*;\s*)",
                r"\1\n    _premiumSvc.getShowBadges().then((v) {\n      if (!mounted) return;\n      setState(() => _showBadges = v);\n    });\n    _premiumSvc.getFreeLimit(fallback: 30).then((v) {\n      if (!mounted) return;\n      setState(() => _freeLimit = v);\n    });\n",
                p,
                count=1
            )
    else:
        # create initState if missing
        m = re.search(r"class\s+_EbShoppingPageState\s+extends\s+State<[^>]+>\s*\{", p)
        if not m:
            raise SystemExit("Fant ikke _EbShoppingPageState for å sette inn initState")
        init = """
  @override
  void initState() {
    super.initState();
    _premiumSvc.getShowBadges().then((v) {
      if (!mounted) return;
      setState(() => _showBadges = v);
    });
    _premiumSvc.getFreeLimit(fallback: 30).then((v) {
      if (!mounted) return;
      setState(() => _freeLimit = v);
    });
  }

""".lstrip()
        p = p[:m.end()] + "\n" + init + p[m.end():]

# Add admin dialog method (debug-only). Insert before build() if missing.
if "_showAdminPanel" not in p:
    anchor = re.search(r"\n\s*@override\s*\n\s*Widget\s+build\(", p)
    if not anchor:
        raise SystemExit("Fant ikke build() for å sette inn admin-panel")
    method = """
  Future<void> _showAdminPanel() async {
    if (!kDebugMode) return; // kun DEG (debug)
    final isPremium = await _premiumSvc.getIsPremium();
    final showBadges = await _premiumSvc.getShowBadges();
    final freeLimit = await _premiumSvc.getFreeLimit(fallback: _freeLimit);

    if (!mounted) return;

    bool tmpPremium = isPremium;
    bool tmpBadges = showBadges;
    double tmpLimit = freeLimit.toDouble();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Admin (debug)'),
          content: StatefulBuilder(
            builder: (ctx, setLocal) {
              return SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      value: tmpPremium,
                      title: const Text('Premium ON/OFF (lokalt)'),
                      onChanged: (v) => setLocal(() => tmpPremium = v),
                    ),
                    SwitchListTile(
                      value: tmpBadges,
                      title: const Text('Vis badges (du styrer)'),
                      onChanged: (v) => setLocal(() => tmpBadges = v),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('FREE limit: ${tmpLimit.round()}'),
                    ),
                    Slider(
                      value: tmpLimit.clamp(5, 300),
                      min: 5,
                      max: 300,
                      divisions: 59,
                      label: '${tmpLimit.round()}',
                      onChanged: (v) => setLocal(() => tmpLimit = v),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Avbryt'),
            ),
            FilledButton(
              onPressed: () async {
                await _premiumSvc.setIsPremium(tmpPremium);
                await _premiumSvc.setShowBadges(tmpBadges);
                await _premiumSvc.setFreeLimit(tmpLimit.round());
                if (!mounted) return;
                setState(() {
                  _showBadges = tmpBadges;
                  _freeLimit = tmpLimit.round();
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Lagre'),
            ),
          ],
        );
      },
    );
  }

""".rstrip("\n") + "\n"
    p = p[:anchor.start()] + "\n" + method + p[anchor.start():]

# Make AppBar title long-press open admin panel (debug-only)
# Replace: title: const Text('EuroBonus Shopping'),
# with GestureDetector wrapper if not already.
if "onLongPress: _showAdminPanel" not in p:
    p = re.sub(
        r"title:\s*const\s*Text\(([^)]+)\)\s*,",
        r"title: GestureDetector(\n            onLongPress: _showAdminPanel,\n            child: const Text(\1),\n          ),",
        p,
        count=1
    )

# Gate logic: wherever FREE_LIMIT or 30 is used for visible list, prefer _freeLimit
# We do a conservative replace of "const int FREE_LIMIT" remnants if any.
p = p.replace("FREE_LIMIT", "_freeLimit")

# If code has "final visible = filtered.take(30).toList();" change to _freeLimit.
p = re.sub(r"\.take\(\s*30\s*\)", ".take(_freeLimit)", p)

# If code builds badges: let’s ensure badges are wrapped with _showBadges
# Very conservative: if PremiumBadge() used, wrap.
p = re.sub(r"(\bPremiumBadge\s*\()",
           r"(_showBadges ? PremiumBadge(",
           p)
# Close the ternary if we opened it and it's not already closed.
# We only patch if we see "_showBadges ? PremiumBadge(" without a matching ":"
if "_showBadges ? PremiumBadge(" in p and ": const SizedBox.shrink()" not in p:
    p = p.replace("_showBadges ? PremiumBadge(", "_showBadges ? PremiumBadge(")
    # Add shrink close after first PremiumBadge(...) widget expression end: we try a simple pattern
    p = re.sub(r"(_showBadges\s*\?\s*PremiumBadge\([^\)]*\)\s*\))",
               r"\1 : const SizedBox.shrink()",
               p, count=1)

page.write_text(p, encoding="utf-8")

print("✅ PRO Q patch: debug-admin (long-press title), showBadges + freeLimit + premium override")
PY

dart format lib/services/premium_service.dart lib/pages/eb_shopping_page.dart >/dev/null || true
flutter analyze || true
echo "✅ PRO Q ferdig. Restart web-server."
