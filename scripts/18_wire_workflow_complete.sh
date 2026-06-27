#!/bin/bash
set -e
TARGET=".github/workflows/bonusvarsel.yml"
cp "$TARGET" "$TARGET.bak_$(date +%Y%m%d_%H%M%S)"
echo "🔒 Backup lagret"

python3 - << 'PYTHON'
with open('.github/workflows/bonusvarsel.yml', 'r') as f:
    content = f.read()

# Legg til to nye steg ETTER collector, FØR notify
old = """      - name: Notify Telegram"""

new = """      - name: Arkiver historikk
        env:
          DATA_DIR: data
        run: node scripts/archive-history.mjs

      - name: Bygg tier-meldinger
        env:
          DATA_DIR: data
          DISPLAY_NAME: "SAS EuroBonus"
        run: node scripts/build-tier-messages.mjs

      - name: Commit historikk til repo
        run: |
          git config user.name "github-actions"
          git config user.email "actions@github.com"
          git add data/history data/tier-messages.json 2>/dev/null || true
          git commit -m "Arkiver historikk $(date +%Y-%m-%d)" 2>/dev/null || echo "Ingen endringer"
          git push 2>/dev/null || echo "Ingenting å pushe"

      - name: Notify Telegram"""

if old in content and 'Arkiver historikk' not in content:
    content = content.replace(old, new, 1)
    with open('.github/workflows/bonusvarsel.yml', 'w') as f:
        f.write(content)
    print('✅ Workflow utvidet med arkiv + tier-bygging + commit')
else:
    print('⚠️  Allerede lagt til eller ikke funnet')
PYTHON

echo ""
echo "📋 Ny workflow-struktur:"
grep "name:" "$TARGET" | grep -v "^name:"
