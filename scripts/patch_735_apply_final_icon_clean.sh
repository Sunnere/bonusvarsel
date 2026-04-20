#!/bin/bash

echo "==> patch_735_apply_final_icon_clean"

ICON_PATH="assets/app_icons/app_icon_master.png"
IOS_PATH="ios/Runner/Assets.xcassets/AppIcon.appiconset"

# 1. Sjekk at ikon finnes
if [ ! -f "$ICON_PATH" ]; then
  echo "❌ Mangler ikon: $ICON_PATH"
  exit 1
fi

# 2. Lag mappe hvis ikke finnes
mkdir -p "$IOS_PATH"

# 3. Slett gamle icons (viktig!)
rm -rf "$IOS_PATH"/*

echo "==> Genererer iOS icons"

# 4. Generer alle størrelser med sips (stabilt, ingen Pillow bugs)
sizes=(20 29 40 60 76 83.5 1024)

for size in "${sizes[@]}"; do
  for scale in 1 2 3; do
    if [[ "$size" == "83.5" && "$scale" != "2" ]]; then continue; fi
    if [[ "$size" == "1024" && "$scale" != "1" ]]; then continue; fi

    px=$(echo "$size * $scale" | bc | cut -d'.' -f1)
    filename="Icon-App-${size}x${size}@${scale}x.png"

    sips -z $px $px "$ICON_PATH" --out "$IOS_PATH/$filename" >/dev/null
  done
done

# 5. Contents.json
cat > "$IOS_PATH/Contents.json" <<JSON
{
  "images" : [
    { "size" : "20x20", "idiom" : "iphone", "filename" : "Icon-App-20x20@2x.png", "scale" : "2x" },
    { "size" : "20x20", "idiom" : "iphone", "filename" : "Icon-App-20x20@3x.png", "scale" : "3x" },
    { "size" : "29x29", "idiom" : "iphone", "filename" : "Icon-App-29x29@2x.png", "scale" : "2x" },
    { "size" : "29x29", "idiom" : "iphone", "filename" : "Icon-App-29x29@3x.png", "scale" : "3x" },
    { "size" : "40x40", "idiom" : "iphone", "filename" : "Icon-App-40x40@2x.png", "scale" : "2x" },
    { "size" : "40x40", "idiom" : "iphone", "filename" : "Icon-App-40x40@3x.png", "scale" : "3x" },
    { "size" : "60x60", "idiom" : "iphone", "filename" : "Icon-App-60x60@2x.png", "scale" : "2x" },
    { "size" : "60x60", "idiom" : "iphone", "filename" : "Icon-App-60x60@3x.png", "scale" : "3x" },
    { "size" : "76x76", "idiom" : "ipad", "filename" : "Icon-App-76x76@1x.png", "scale" : "1x" },
    { "size" : "76x76", "idiom" : "ipad", "filename" : "Icon-App-76x76@2x.png", "scale" : "2x" },
    { "size" : "83.5x83.5", "idiom" : "ipad", "filename" : "Icon-App-83.5x83.5@2x.png", "scale" : "2x" },
    { "size" : "1024x1024", "idiom" : "ios-marketing", "filename" : "Icon-App-1024x1024@1x.png", "scale" : "1x" }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
JSON

echo "==> Rydder cache"

flutter clean

rm -rf ios/Pods
rm -rf ios/Podfile.lock

cd ios
pod install
cd ..

echo ""
echo "✅ Ferdig"
echo ""
echo "Gjør nå:"
echo "1) Slett app fra iPhone"
echo "2) Restart iPhone"
echo "3) flutter pub get"
echo "4) flutter run"
