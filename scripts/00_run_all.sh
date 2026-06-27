#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔══════════════════════════════════════════╗"
echo "║  Bonusvarsel – Notification Setup        ║"
echo "║  Man/Ons/Fre kl 09:00 → Telegram + Mail ║"
echo "╚══════════════════════════════════════════╝"

echo ""
echo "▶ Steg 1/4: notification_service.dart..."
bash "$SCRIPT_DIR/01_create_notification_service.sh"

echo ""
echo "▶ Steg 2/4: Firebase Functions..."
bash "$SCRIPT_DIR/02_create_firebase_function.sh"

echo ""
echo "▶ Steg 3/4: Firestore-sync i alerts_page..."
bash "$SCRIPT_DIR/03_patch_alerts_page_sync_firestore.sh"

echo ""
echo "▶ Steg 4/4: E-post og Telegram lagring..."
bash "$SCRIPT_DIR/04_patch_save_email_telegram_firestore.sh"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  ✅ Ferdig! Gjenstår:                    ║"
echo "║  1. Fyll inn secrets i script 05         ║"
echo "║  2. bash scripts/05_deploy_and_set_secrets.sh ║"
echo "╚══════════════════════════════════════════╝"
