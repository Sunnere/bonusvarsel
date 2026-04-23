#!/bin/bash
set -e

# Oppdater tableBody, tableBorder og legg til tableHead-styling
cat > /tmp/table_style_patch.py << 'PYEOF'
import re

with open('lib/pages/ai_chat_page.dart', 'r') as f:
    content = f.read()

old = '''                                          tableBody: const TextStyle(fontSize: 11,
                                          ),
                                          tableBorder: TableBorder.all(
                                            color: Colors.grey,
                                            width: 0.5,
                                          ),'''

new = '''                                          tableBody: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF1A1A2E),
                                          ),
                                          tableHead: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          tableBorder: TableBorder.all(
                                            color: Color(0xFF1A1A2E),
                                            width: 0.8,
                                          ),
                                          tableColumnWidth: const FlexColumnWidth(),
                                          tableHeadAlign: TextAlign.center,
                                          tableCellsPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),'''

content = content.replace(old, new)

with open('lib/pages/ai_chat_page.dart', 'w') as f:
    f.write(content)

print("✅ Tabellfarger oppdatert")
PYEOF

python3 /tmp/table_style_patch.py
