#!/bin/bash
set -e

sed -i '' 's/Svar alltid på norsk. Vær konkret og praktisk. Bruk gjerne regneeksempler./Svar alltid på norsk. Vær konkret og praktisk. Bruk gjerne regneeksempler.\nBruk ALDRI markdown-tabeller i svarene dine – bruk heller bullet-lister med fet tekst. Mobilskjermen er smal./' lib/services/ai_service.dart

echo "✅ Prompt oppdatert – ingen tabeller"
