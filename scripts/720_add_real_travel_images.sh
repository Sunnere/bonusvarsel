#!/bin/bash

echo "==> 720_add_real_travel_images"

mkdir -p assets/images/travel

# --- SAVE IMAGES ---

cat > assets/images/travel/hero_winter.jpg << 'IMG'
$(curl -s https://images.unsplash.com/photo-1605540436563-5bca919ae766)
IMG

cat > assets/images/travel/need_luggage.jpg << 'IMG'
$(curl -s https://images.unsplash.com/photo-1522708323590-d24dbb6b0267)
IMG

cat > assets/images/travel/hero_beach.jpg << 'IMG'
$(curl -s https://images.unsplash.com/photo-1507525428034-b723cf961d3e)
IMG

# --- ENSURE PUBSPEC HAS ASSETS ---

if ! grep -q "assets/images/travel/" pubspec.yaml; then
  echo "Legger til assets i pubspec.yaml"
  awk '
  /flutter:/ {
    print;
    print "  assets:";
    print "    - assets/images/travel/";
    next
  }
  { print }
  ' pubspec.yaml > pubspec.yaml.tmp && mv pubspec.yaml.tmp pubspec.yaml
fi

echo "✅ Bilder lagt til"
echo "Kjør nå:"
echo "flutter pub get"
echo "flutter run -d macos"

