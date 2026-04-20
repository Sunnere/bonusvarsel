#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="lib/pages/premium_page.dart"

echo "==> patch_765_read_paywall_arguments_in_premium_page"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_765_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path
import re

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
report = []

# 1) add state flags if missing
state_marker = "class _PremiumPageState extends State<PremiumPage> {"
if state_marker in text and "_routeArgsApplied" not in text:
    insert = """
  bool _routeArgsApplied = false;
  String? _entryAction;
  String? _entryPlanId;

"""
    text = text.replace(state_marker, state_marker + insert, 1)
    report.append("la til route-state felter")

# 2) add didChangeDependencies if missing
if "didChangeDependencies()" not in text:
    m = re.search(r"(class _PremiumPageState extends State<PremiumPage> \{.*?\n)", text, flags=re.DOTALL)
    if m:
        block = """
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgsApplied) return;
    _routeArgsApplied = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final action = args['action']?.toString();
      final planId = (args['planId'] ?? args['billingCycle'])?.toString();

      _entryAction = action;
      _entryPlanId = planId;

      if (planId != null && mounted) {
        setState(() {
          if (planId.toLowerCase().contains('year')) {
            _billingCycle = 'yearly';
          } else if (planId.toLowerCase().contains('month')) {
            _billingCycle = 'monthly';
          }
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (action == 'restore') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gjenoppretting av kjøp åpnet')),
          );
        } else if (planId != null) {
          final label = _billingCycle == 'yearly' ? 'Årsplan valgt' : 'Månedsplan valgt';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(label)),
          );
        }
      });
    }
  }

"""
        text = text.replace(m.group(1), m.group(1) + block, 1)
        report.append("la til didChangeDependencies for route-arguments")

# 3) add small helper info strip in build if possible
if "_entryPlanId" in text and "Valgt fra paywall" not in text:
    pattern = r"(return\s+Scaffold\(\s*.*?body:\s*)([^,]+,)"
    # too risky to auto-insert there; skip unless specific later
    report.append("route-lesing lagt til; ingen ekstra UI-strip auto-injisert")

path.write_text(text)
Path("lib/paywall/_patch_765_report.txt").write_text("\n".join(report) + "\n")
print("\n".join(report))
PY

echo
echo "==> Rapport"
cat lib/paywall/_patch_765_report.txt || true

echo
echo "Neste:"
echo "1) flutter analyze"
echo "2) test Fortsett til betaling"
echo "3) se om monthly/yearly velges riktig"
