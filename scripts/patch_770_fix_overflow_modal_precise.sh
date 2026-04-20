#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_770_fix_overflow_modal_precise"

TRIGGER_FILE="lib/services/paywall_trigger_service.dart"
SHEET_FILE="lib/widgets/premium_paywall_sheet.dart"

if [ ! -f "$TRIGGER_FILE" ]; then
  echo "❌ Fant ikke $TRIGGER_FILE"
  exit 1
fi

if [ ! -f "$SHEET_FILE" ]; then
  echo "❌ Fant ikke $SHEET_FILE"
  exit 1
fi

cp "$TRIGGER_FILE" "$TRIGGER_FILE.bak_770_$(date +%Y%m%d_%H%M%S)"
cp "$SHEET_FILE" "$SHEET_FILE.bak_770_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path
import re

trigger_path = Path("lib/services/paywall_trigger_service.dart")
sheet_path = Path("lib/widgets/premium_paywall_sheet.dart")

trigger = trigger_path.read_text()
sheet = sheet_path.read_text()

report = []

# --- 1) Fix bottom sheet trigger ---
# Force rootNavigator + scrollable modal settings if not already present.
if "showModalBottomSheet<void>(" in trigger:
    trigger = trigger.replace(
        "await showModalBottomSheet<void>(",
        "await showModalBottomSheet<void>(\n      useRootNavigator: true,\n      isScrollControlled: true,\n      useSafeArea: true,\n      backgroundColor: Colors.transparent,",
        1,
    )
    report.append("oppdaterte showModalBottomSheet med rootNavigator/isScrollControlled/useSafeArea")
else:
    report.append("ADVARSEL: fant ikke showModalBottomSheet<void>(")

# Wrap PremiumPaywallSheet in a constrained scrollable shell if not already wrapped
if "FractionallySizedBox(" not in trigger and "DraggableScrollableSheet(" not in trigger:
    trigger = re.sub(
        r"builder:\s*\(context\)\s*=>\s*(const\s+)?PremiumPaywallSheet\(",
        "builder: (context) => FractionallySizedBox(\n"
        "        heightFactor: 0.92,\n"
        "        child: ClipRRect(\n"
        "          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),\n"
        "          child: Material(\n"
        "            color: Colors.transparent,\n"
        "            child: PremiumPaywallSheet(",
        trigger,
        count=1,
    )

    # Close wrappers right after first matching PremiumPaywallSheet(...);
    trigger, n = re.subn(
        r"(PremiumPaywallSheet\([^;]*?\))\s*;",
        r"\1,\n"
        r"          ),\n"
        r"        ),\n"
        r"      );",
        trigger,
        count=1,
        flags=re.DOTALL,
    )
    if n:
        report.append("wrapped PremiumPaywallSheet i FractionallySizedBox + ClipRRect + Material")
    else:
        report.append("ADVARSEL: klarte ikke lukke wrapper rundt PremiumPaywallSheet")
else:
    report.append("triggeren hadde allerede wrapper")

trigger_path.write_text(trigger)

# --- 2) Fix sheet layout itself ---
# Make the sheet scroll if content is taller than viewport.
if "SingleChildScrollView(" not in sheet:
    # Try common pattern: body/content Column -> wrap in SingleChildScrollView
    sheet, n1 = re.subn(
        r"(child:\s*)Column\(",
        r"\1SingleChildScrollView(\n              child: Column(",
        sheet,
        count=1,
    )
    if n1:
        # Close SingleChildScrollView before the next container close near the end of the main child tree
        sheet, n2 = re.subn(
            r"(\n\s*\)\s*,\n\s*\)\s*,\n\s*\)\s*;\s*\n\})",
            r"\n              ),\1",
            sheet,
            count=1,
        )
        report.append("la til SingleChildScrollView rundt hoved-Column i premium_paywall_sheet")
    else:
        report.append("ADVARSEL: fant ikke enkel child: Column( å wrappe")
else:
    report.append("premium_paywall_sheet hadde allerede SingleChildScrollView")

# Add mainAxisSize min to first Column if missing
if "mainAxisSize: MainAxisSize.min" not in sheet:
    sheet, n = re.subn(
        r"Column\(\n",
        "Column(\n              mainAxisSize: MainAxisSize.min,\n",
        sheet,
        count=1,
    )
    if n:
        report.append("la til mainAxisSize: MainAxisSize.min")
    else:
        report.append("ADVARSEL: klarte ikke legge til mainAxisSize")

# Add bottom padding from viewInsets if not already present
if "MediaQuery.of(context).viewInsets.bottom" not in sheet:
    sheet, n = re.subn(
        r"(padding:\s*const EdgeInsets\.fromLTRB\([^\n]+\),)",
        r"\1",
        sheet,
        count=1,
    )
    # no-op if not found; we avoid risky padding rewrites
    report.append("lot eksisterende padding stå; ingen viewInsets-padding tvunget inn")

sheet_path.write_text(sheet)

report_path = Path("lib/paywall/_patch_770_report.txt")
report_path.write_text("\n".join(report) + "\n")
print("\n".join(report))
PY

echo
echo "==> Rapport"
cat lib/paywall/_patch_770_report.txt || true

echo
echo "Neste:"
echo "1) flutter analyze"
echo "2) test locked_ad / Elite-modal"
echo "3) bekreft at gul/svart overflow-stripen er borte"
echo
echo "Hvis det fortsatt overflow'er, kjør disse og lim inn output:"
echo "sed -n '1,260p' lib/widgets/premium_paywall_sheet.dart"
echo "sed -n '1,220p' lib/services/paywall_trigger_service.dart"
