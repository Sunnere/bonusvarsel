#!/bin/bash
set -e

python3 << 'PYEOF'
path = "/Users/sunnerehelse/bonusvarsel/lib/pages/travel_club_page.dart"
with open(path, "r") as f:
    content = f.read()

# Erstatt import av PaywallPage med PaywallPreviewPage
content = content.replace(
    "import '../pages/paywall_page.dart';",
    "import '../paywall/paywall_preview_page.dart';"
)
content = content.replace(
    "import 'paywall_page.dart';",
    "import '../paywall/paywall_preview_page.dart';"
)

# Erstatt bruken
content = content.replace(
    "builder: (_) => PaywallPage(subs: subs),",
    "builder: (_) => const PaywallPreviewPage(),"
)

with open(path, "w") as f:
    f.write(content)

print("✅ travel_club_page.dart oppdatert")
PYEOF
