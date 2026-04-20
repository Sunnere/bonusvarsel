#!/bin/bash
echo "Sjekker URLer..."
curl -sI "https://www.lunar.app/no/kredittkort/sas-eurobonus" | head -3
echo "---"
curl -sI "https://www.sas.no/eurobonus/partnere/kredittkort/" | head -3
echo "---"
curl -sI "https://www.trumf.no/trumfvisa" | head -3
