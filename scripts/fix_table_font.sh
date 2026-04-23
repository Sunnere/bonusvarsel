#!/bin/bash
set -e

sed -i '' 's/tableBody: const TextStyle(\n                                            fontSize: 13,/tableBody: const TextStyle(fontSize: 11,/' lib/pages/ai_chat_page.dart

echo "✅ Tabell-font justert"
