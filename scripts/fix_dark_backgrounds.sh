#!/bin/bash
set -e

# Fix home_page.dart
sed -i '' 's/backgroundColor: const Color(0xFF1A1A2E)/backgroundColor: Theme.of(context).scaffoldBackgroundColor/g' ~/bonusvarsel/lib/pages/home_page.dart

# Fix ai_chat_page.dart  
sed -i '' 's/backgroundColor: const Color(0xFF1A1A2E)/backgroundColor: Theme.of(context).scaffoldBackgroundColor/g' ~/bonusvarsel/lib/pages/ai_chat_page.dart

# Fix login_page.dart
sed -i '' 's/backgroundColor: const Color(0xFF0F1115)/backgroundColor: Theme.of(context).scaffoldBackgroundColor/g' ~/bonusvarsel/lib/pages/login_page.dart

echo "✅ Mørke bakgrunner fjernet"
