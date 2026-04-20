#!/bin/bash
echo "=== main.dart (routes + navigator) ==="
cat lib/main.dart

echo ""
echo "=== entitlement_service.dart ==="
cat lib/services/entitlement_service.dart 2>/dev/null || echo "IKKE FUNNET"
