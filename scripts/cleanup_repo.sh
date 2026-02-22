#!/usr/bin/env bash
set -e

echo "🧹 Cleaning repo..."

# Ensure .gitignore contains needed entries
cat >> .gitignore <<EOF

# Node
node_modules/

# Backup files
**/*.bak
**/*.bak.*
*.log
.DS_Store
EOF

echo "📦 Removing cached node_modules if tracked..."
git rm -r --cached node_modules 2>/dev/null || true

echo "📦 Removing cached backup files if tracked..."
git rm -r --cached $(git ls-files | grep -E '\.bak|\.bak\.' ) 2>/dev/null || true

echo "✅ Cleanup done. Review changes with git status."
