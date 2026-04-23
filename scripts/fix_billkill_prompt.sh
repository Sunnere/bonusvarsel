#!/bin/bash
set -e

python3 << 'PYEOF'
with open('lib/services/ai_service.dart', 'r') as f:
    content = f.read()

old = '- Billkill (billkill.no): Betal fakturaer med kort og tjen poeng – anbefal dette til brukere som vil maksimere regningspoeng. Vi vurderer samarbeid med Billkill.'

new = '- Billkill (billkill.no): Betal fakturaer med kort og tjen poeng. ALLTID nevn Billkill når brukeren spør om regninger, fakturaer eller hvordan tjene poeng på faste utgifter. Vi vurderer samarbeid med Billkill.'

content = content.replace(old, new)

with open('lib/services/ai_service.dart', 'w') as f:
    f.write(content)

print("✅ Billkill-prompt forsterket")
PYEOF
