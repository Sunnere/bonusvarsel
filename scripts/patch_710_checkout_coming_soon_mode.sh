#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/checkout_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

cp "$FILE" "${FILE}.bak_710_checkout_coming_soon_mode"
echo "✅ Backup laget: ${FILE}.bak_710_checkout_coming_soon_mode"

python3 - <<'PY'
from pathlib import Path

path = Path("lib/pages/checkout_page.dart")
text = path.read_text()
original = text

# CTA button
old_button = """                onPressed: () async {
                  await CheckoutService.instance.setBilling(billing);
                  final msg = await CheckoutService.instance.buySelectedVerbose();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                },"""

new_button = """                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kommer snart'),
                    ),
                  );
                },"""

if old_button in text:
    text = text.replace(old_button, new_button, 1)

# CTA label
text = text.replace(
    "                      ? 'Start årlig – spar penger'\n                      : 'Start abonnement'",
    "                      ? 'Kommer snart'\n                      : 'Kommer snart'"
)

# Restore button
old_restore = """            TextButton(
              onPressed: () async {
                await CheckoutService.instance.restorePurchases();
                if (!mounted) return;
                final plan = EntitlementService.instance.plan;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Restore kjørt. Nåværende plan: $plan')),
                );
              },
              child: const Text('Gjenopprett kjøp'),
            ),"""

new_restore = """            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kommer snart'),
                  ),
                );
              },
              child: const Text('Kjøp kommer snart'),
            ),"""

if old_restore in text:
    text = text.replace(old_restore, new_restore, 1)

# Add a short info box if not already present
marker = "            const SizedBox(height: 20),\n\n            // 🔥 VALUE"
insert = """            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: const Text(
                'Betaling og aktivering kommer snart. Du kan allerede se nivåene og hva som inngår.',
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.35,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 VALUE"""
if marker in text and "Betaling og aktivering kommer snart" not in text:
    text = text.replace(marker, insert, 1)

if text == original:
    print("⚠️ Ingen endring ble gjort.")
else:
    path.write_text(text)
    print("✅ CheckoutPage satt til Kommer snart-modus")
PY

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter run -d 00008110-001138643E60401E"
