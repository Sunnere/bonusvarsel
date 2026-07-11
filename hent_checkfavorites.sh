#!/bin/bash
# Henter checkFavoritesAndNotify-funksjonen fra server.js for gjennomgang
# Kjør fra: ~/bonusvarsel (eller riktig mappe)

grep -n "checkFavoritesAndNotify" api/server.js
echo "---"
echo "Full funksjon (200 linjer etter funksjonsstart):"
awk '/async function checkFavoritesAndNotify/,/^}/' api/server.js
