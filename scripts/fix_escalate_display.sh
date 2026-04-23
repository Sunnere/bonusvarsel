#!/bin/bash
set -e

# Fiks: Skjul ESCALATE-teksten, vis bare støttemeldingen
sed -i '' 's/if (text.startsWith('\''ESCALATE:'\''))/if (text.contains('\''ESCALATE:'\''))/' lib/services/ai_service.dart

echo "✅ ESCALATE-sjekk oppdatert"
