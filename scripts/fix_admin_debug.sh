#!/bin/bash
cp lib/pages/eb_shopping_page.dart lib/pages/eb_shopping_page.dart.bak

sed -i '' 's/Future<void> _openDebugAdmin() async {\n    if (!kDebugMode) return;//Future<void> _openDebugAdmin() async {/' lib/pages/eb_shopping_page.dart

# Python er mer pålitelig for denne erstatningen
python3 << 'PYTHON'
with open('lib/pages/eb_shopping_page.dart', 'r') as f:
    content = f.read()

old = '''  Future<void> _openDebugAdmin() async {
    if (!kDebugMode) return;'''

new = '''  Future<void> _openDebugAdmin() async {
    // kDebugMode-sjekk fjernet midlertidig for testing'''

content = content.replace(old, new)

with open('lib/pages/eb_shopping_page.dart', 'w') as f:
    f.write(content)

print("✅ Admin tilgjengelig uten debug-modus")
PYTHON

echo "✅ Ferdig"
