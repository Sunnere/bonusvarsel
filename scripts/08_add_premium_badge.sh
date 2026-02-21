#!/usr/bin/env bash
set -euo pipefail

mkdir -p scripts lib/widgets

# 1) Lag widget: PremiumBadge
cat > lib/widgets/premium_badge.dart <<'DART'
import 'package:flutter/material.dart';

import '../pages/premium_page.dart';
import '../services/premium_service.dart';

class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final premium = PremiumService();

    return FutureBuilder<bool>(
      future: premium.isPremium(), // forventes å finnes i prosjektet ditt
      builder: (context, snap) {
        final isPremium = snap.data == true;

        final bg = isPremium
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface;
        final fg = isPremium
            ? Colors.white
            : Theme.of(context).colorScheme.primary;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPremium ? Icons.verified_rounded : Icons.lock_outline,
                    size: 16,
                    color: fg,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPremium ? 'PRO' : 'PRO',
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
DART

# 2) Patch AppBar: legg til actions: [PremiumBadge()]
python - <<'PY'
from pathlib import Path
import re

candidates = [
    Path("lib/pages/home_page.dart"),
    Path("lib/main.dart"),
]

target = None
for p in candidates:
    if p.exists():
        txt = p.read_text(encoding="utf-8")
        # må ha AppBar + Scaffold-ish
        if "AppBar(" in txt:
            target = p
            break

if target is None:
    raise SystemExit("Fant ikke home_page.dart eller main.dart med AppBar(. (Gi meg filnavnet du bruker for startsiden)")

s = target.read_text(encoding="utf-8")

# sørg for import
if "premium_badge.dart" not in s:
    # sett import etter flutter/material.dart hvis mulig
    if "package:flutter/material.dart" in s:
        s = re.sub(
            r"(import\s+'package:flutter/material\.dart';\s*\n)",
            r"\1import '../widgets/premium_badge.dart';\n",
            s,
            count=1,
        )
        # hvis vi patchet main.dart (ikke i pages/), import-path må være 'widgets/...'
        if target.name == "main.dart":
            s = s.replace("import '../widgets/premium_badge.dart';", "import 'widgets/premium_badge.dart';")
    else:
        # fallback: legg på toppen
        prefix = "import 'widgets/premium_badge.dart';\n" if target.name == "main.dart" else "import '../widgets/premium_badge.dart';\n"
        s = prefix + s

# finn AppBar(...) første forekomst og legg til actions
#  - hvis actions finnes: prepend PremiumBadge()
#  - hvis actions ikke finnes: sett inn actions: [const PremiumBadge()],
def add_actions(match: re.Match) -> str:
    block = match.group(0)
    if "actions:" in block:
        # actions: [ ... ] -> actions: [const PremiumBadge(), ...]
        block2 = re.sub(
            r"actions\s*:\s*\[\s*",
            "actions: [const PremiumBadge(), ",
            block,
            count=1,
        )
        return block2
    else:
        # sett inn før closing );
        # finn siste ')' før '),'
        # enkel: putt "actions: [...]" før ")," i AppBar-kallet
        block2 = re.sub(
            r"\)\s*,\s*$",
            "),\n          actions: const [PremiumBadge()],\n        ),",
            block,
            flags=re.M,
            count=1,
        )
        # hvis ikke traff (pga formatting), fallback:
        if block2 == block:
            block2 = block.rstrip()
            if block2.endswith("),"):
                block2 = block2[:-2] + ",\n          actions: const [PremiumBadge()],\n        ),"
        return block2

# ta bare første AppBar(...) i fila
m = re.search(r"AppBar\s*\([\s\S]*?\)\s*,", s)
if not m:
    raise SystemExit(f"Fant ikke et AppBar(...) i {target}")

new_block = add_actions(m)
if new_block == m.group(0) and "PremiumBadge" not in m.group(0):
    # fallback for actions-existing case with weird spacing
    new_block = m.group(0).replace("actions:", "actions: const [PremiumBadge()],\n          // actions:")

s2 = s[:m.start()] + new_block + s[m.end():]

target.write_text(s2, encoding="utf-8")
print(f"✅ PremiumBadge lagt til i AppBar i {target}")
PY

dart format lib/widgets/premium_badge.dart lib/pages/home_page.dart lib/main.dart 2>/dev/null || true
flutter analyze
