#!/usr/bin/env bash
set -euo pipefail

echo "==> Repo inspection for EB shopping integration inputs"
mkdir -p .tmp_ai

{
  echo "### FILES"
  find lib -type f | sort
  echo

  echo "### MATCH: eb_shopping_page"
  grep -RIn "eb_shopping_page" lib || true
  echo

  echo "### MATCH: class OffersFeedRepository"
  grep -RIn "class OffersFeedRepository" lib || true
  echo

  echo "### MATCH: fetchOffersFeed"
  grep -RIn "fetchOffersFeed" lib || true
  echo

  echo "### MATCH: getOffersFeed"
  grep -RIn "getOffersFeed" lib || true
  echo

  echo "### MATCH: legacy offer loaders"
  grep -RInE "_load.*offer|load.*offer|offers.*load|legacy.*offer|Offer" lib/pages lib/features lib/widgets 2>/dev/null || true
  echo

  echo "### MATCH: deeplink / cta / url"
  grep -RInE "deeplink|cta|targetUrl|trackingUrl|launchUrl|url_launcher" lib 2>/dev/null || true
  echo

  echo "### MATCH: EB shopping widgets/cards"
  grep -RInE "OfferCard|offer card|shopping|eb shopping|EuroBonus" lib/pages lib/widgets 2>/dev/null || true
  echo
} > .tmp_ai/eb_shopping_integration_inputs.txt

echo "✅ Skrev .tmp_ai/eb_shopping_integration_inputs.txt"
sed -n '1,260p' .tmp_ai/eb_shopping_integration_inputs.txt
