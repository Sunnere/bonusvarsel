#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/checkout_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

cp "$FILE" "${FILE}.bak_711_force_checkout_coming_soon_and_fix_overflow"
echo "✅ Backup laget: ${FILE}.bak_711_force_checkout_coming_soon_and_fix_overflow"

python3 - <<'PY'
from pathlib import Path
import re

path = Path("lib/pages/checkout_page.dart")
text = path.read_text()
orig = text

# 1) Ikke init IAP fra checkout page
text = text.replace(
"""  @override
  void initState() {
    super.initState();
    CheckoutService.instance.init();
  }
""",
"""  @override
  void initState() {
    super.initState();
  }
"""
)

# 2) Gjør body scrollable og fjern overflow
text = text.replace(
"""      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [""",
"""      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: ["""
)

# close wrappers
text = text.replace(
"""          ],
        ),
      ),""",
"""            ],
          ),
        ),
      ),""",
1
)

# 3) Tving alle CTA-er til kommer snart
text = re.sub(
    r"""onPressed:\s*\(\)\s*async\s*\{.*?SnackBar\(content:\s*Text\(msg\)\).*?\},""",
    """onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kommer snart')),
                  );
                },""",
    text,
    flags=re.DOTALL
)

text = re.sub(
    r"""onPressed:\s*\(\)\s*async\s*\{.*?buySelectedVerbose\(\).*?\},""",
    """onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kommer snart')),
                  );
                },""",
    text,
    flags=re.DOTALL
)

text = re.sub(
    r"""onPressed:\s*\(\)\s*async\s*\{.*?restorePurchases\(\).*?\},""",
    """onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kommer snart')),
                );
              },""",
    text,
    flags=re.DOTALL
)

# 4) Ensartet tekst på knapp
text = text.replace(
"""                  billing == 'yearly'
                      ? 'Start årlig – spar penger'
                      : 'Start abonnement'""",
"""                  'Kommer snart'"""
)

text = text.replace(
"""                  billing == 'yearly'
                      ? 'Kommer snart'
                      : 'Kommer snart'""",
"""                  'Kommer snart'"""
)

# 5) Bytt restore-knappens label hvis nødvendig
text = text.replace(
"child: const Text('Gjenopprett kjøp'),",
"child: const Text('Kommer snart'),"
)
text = text.replace(
"child: const Text('Kjøp kommer snart'),",
"child: const Text('Kommer snart'),"
)

if text == orig:
    print("⚠️ Ingen endringer gjort.")
else:
    path.write_text(text)
    print("✅ CheckoutPage tvunget til Kommer snart + overflow fix")
PY

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter run -d 00008110-001138643E60401E"
