#!/bin/bash
set -e

# Legg til import øverst hvis den ikke finnes
if ! grep -q "ai_chat_page.dart" lib/pages/home_page.dart; then
  sed -i '' "1s/^/import 'ai_chat_page.dart';\n/" lib/pages/home_page.dart
  echo "✅ Import lagt til"
else
  echo "ℹ️  Import finnes allerede"
fi

# Legg til floatingActionButton rett før bottomNavigationBar
sed -i '' "s/      bottomNavigationBar: NavigationBar(/      floatingActionButton: FloatingActionButton(\n        backgroundColor: const Color(0xFF1A1A2E),\n        tooltip: 'Spør Bonusvarsel',\n        onPressed: () => Navigator.push(\n          context,\n          MaterialPageRoute(builder: (_) => const AiChatPage()),\n        ),\n        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),\n      ),\n      bottomNavigationBar: NavigationBar(/" lib/pages/home_page.dart

echo "✅ Flytende chat-knapp lagt til i home_page.dart"
