#!/bin/bash
set -e

# Oppdater ai_chat_page.dart med markdown-rendering
sed -i '' "s/import 'package:flutter\/material.dart';/import 'package:flutter\/material.dart';\nimport 'package:flutter_markdown\/flutter_markdown.dart';/" lib/pages/ai_chat_page.dart

# Bytt ut Text-widget med MarkdownBody for assistant-meldinger
sed -i '' "s/child: Text(/child: isUser ? Text(/" lib/pages/ai_chat_page.dart

echo "✅ Markdown-import lagt til"
