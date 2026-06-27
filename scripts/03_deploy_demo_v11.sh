#!/bin/bash
# =====================================================
# BonusVarsel AI Booking — Deploy demo til Firebase
# =====================================================
# Kjør fra terminalen:
#   bash ~/Downloads/03_deploy_demo_v11.sh
# =====================================================

set -e

PROJECT_ID="marketplace-app-f5152"
DEPLOY_DIR="$HOME/bonusvarsel-demo-v11"

echo "════════════════════════════════════════════════"
echo "  BonusVarsel AI — Deploy demo v11"
echo "════════════════════════════════════════════════"
echo ""

# Sjekk Firebase CLI
command -v firebase >/dev/null 2>&1 || {
  echo "❌ Firebase CLI mangler."
  echo "   Kjør: npm install -g firebase-tools"
  exit 1
}

# Sjekk innlogget
echo "🔍 Sjekker Firebase-innlogging..."
firebase projects:list --json 2>/dev/null | grep -q "$PROJECT_ID" || {
  echo "⚠️  Ikke logget inn. Kjører: firebase login"
  firebase login
}

echo "✅ Firebase OK — prosjekt: $PROJECT_ID"
echo ""

# Lag deploy-mappe
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/public"

# firebase.json
cat > "$DEPLOY_DIR/firebase.json" << 'EOF'
{
  "hosting": {
    "public": "public",
    "ignore": ["firebase.json", "**/.*"],
    "headers": [
      {
        "source": "**",
        "headers": [
          { "key": "Cache-Control", "value": "no-cache" },
          { "key": "Access-Control-Allow-Origin", "value": "*" }
        ]
      }
    ]
  }
}
EOF

# .firebaserc
cat > "$DEPLOY_DIR/.firebaserc" << EOF
{
  "projects": {
    "default": "$PROJECT_ID"
  }
}
EOF

# Kopier demo-filen
cp "$HOME/Downloads/index.html" "$DEPLOY_DIR/public/index.html" 2>/dev/null || {
  echo "⚠️  Fant ikke ~/Downloads/index.html"
  echo "   Last ned index.html fra Claude og legg den i ~/Downloads/"
  echo "   Kjør deretter scriptet på nytt."
  exit 1
}

echo "✅ Demo-filer klare"
echo ""

# Deploy
cd "$DEPLOY_DIR"
echo "🚀 Deployer til Firebase..."
firebase deploy --only hosting --project "$PROJECT_ID"

echo ""
echo "════════════════════════════════════════════════"
echo "  ✅ Demo er live!"
echo ""
echo "  🔗 https://$PROJECT_ID.web.app"
echo ""
echo "  Send denne lenken til salongene!"
echo "════════════════════════════════════════════════"
