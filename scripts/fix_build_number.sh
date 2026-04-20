#!/bin/bash
echo "=== Nåværende versjon i pubspec.yaml ==="
grep "^version:" pubspec.yaml

echo ""
echo "=== Nåværende build number i iOS ==="
grep "CURRENT_PROJECT_VERSION" ios/Runner.xcodeproj/project.pbxproj | head -5
grep "MARKETING_VERSION" ios/Runner.xcodeproj/project.pbxproj | head -5
