#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
PUBSPEC="$ROOT/pubspec.yaml"
ICON_DIR="$ROOT/assets/app_icons"
ICON_PNG="$ICON_DIR/bonusvarsel_app_icon.png"

if [ ! -f "$PUBSPEC" ]; then
  echo "❌ Fant ikke pubspec.yaml. Kjør scriptet fra repo-roten."
  exit 1
fi

mkdir -p "$ICON_DIR"
cp "$PUBSPEC" "${PUBSPEC}.bak_714_generate_app_icon_and_wire_launcher_icons"
echo "✅ Backup laget: ${PUBSPEC}.bak_714_generate_app_icon_and_wire_launcher_icons"

python3 - <<'PY'
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

out = Path("assets/app_icons/bonusvarsel_app_icon.png")
out.parent.mkdir(parents=True, exist_ok=True)

size = 1024
img = Image.new("RGBA", (size, size), (6, 27, 51, 255))
draw = ImageDraw.Draw(img)

# soft radial glow
glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
gdraw = ImageDraw.Draw(glow)
for r, a in [(420, 30), (340, 40), (260, 55)]:
    bbox = (size//2-r, size//2-r, size//2+r, size//2+r)
    gdraw.ellipse(bbox, fill=(24, 102, 74, a))
glow = glow.filter(ImageFilter.GaussianBlur(50))
img = Image.alpha_composite(img, glow)

draw = ImageDraw.Draw(img)

# rounded card border feel
margin = 42
draw.rounded_rectangle(
    (margin, margin, size-margin, size-margin),
    radius=210,
    outline=(214, 183, 86, 180),
    width=8,
)

# simple "B" monogram block
panel = (210, 180, 530, 844)
draw.rounded_rectangle(panel, radius=90, fill=(14, 92, 66, 255))

# B stem
draw.rounded_rectangle((292, 280, 372, 744), radius=36, fill=(255, 248, 230, 255))
# top bowl
draw.rounded_rectangle((340, 252, 508, 470), radius=92, outline=(255, 248, 230, 255), width=48)
# bottom bowl
draw.rounded_rectangle((340, 510, 524, 772), radius=110, outline=(255, 248, 230, 255), width=48)

# airplane / upward value mark
gold = (228, 199, 110, 255)
shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
sdraw = ImageDraw.Draw(shadow)
plane = [(610, 610), (835, 430), (772, 603), (888, 646), (842, 708), (726, 664), (707, 790)]
sdraw.polygon(plane, fill=(0,0,0,120))
shadow = shadow.filter(ImageFilter.GaussianBlur(16))
img = Image.alpha_composite(img, shadow)

draw = ImageDraw.Draw(img)
draw.polygon(plane, fill=gold)

# small spark/star
star = [(716, 252), (736, 304), (790, 322), (738, 342), (720, 396), (700, 344), (646, 326), (698, 306)]
draw.polygon(star, fill=(255, 236, 170, 255))

# subtle bottom text bar feel
draw.rounded_rectangle((188, 858, 836, 910), radius=26, fill=(255,255,255,28))

img.convert("RGB").save(out, "PNG", optimize=True)
print(f"✅ Laget ikon: {out}")
PY

python3 - <<'PY'
from pathlib import Path
pub = Path("pubspec.yaml")
text = pub.read_text()

if "flutter_launcher_icons:" not in text:
    if "dev_dependencies:" not in text:
        text += "\ndev_dependencies:\n"
    if "flutter_launcher_icons:" not in text:
        text = text.replace(
            "dev_dependencies:\n",
            "dev_dependencies:\n  flutter_launcher_icons: ^0.14.1\n",
            1
        )

config = """
flutter_launcher_icons:
  android: true
  ios: true
  image_path: assets/app_icons/bonusvarsel_app_icon.png
  remove_alpha_ios: true
  adaptive_icon_background: "#061B33"
  adaptive_icon_foreground: assets/app_icons/bonusvarsel_app_icon.png
"""
if "flutter_launcher_icons:" in text and "image_path: assets/app_icons/bonusvarsel_app_icon.png" not in text:
    text += "\n" + config.strip() + "\n"

pub.write_text(text)
print("✅ pubspec.yaml oppdatert")
PY

echo
echo "==> flutter pub get"
flutter pub get

echo
echo "==> Genererer launcher icons"
dart run flutter_launcher_icons

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "✅ Ferdig."
echo "Ikonfil:"
echo "  assets/app_icons/bonusvarsel_app_icon.png"
echo
echo "Neste steg:"
echo "  1) flutter run -d 00008110-001138643E60401E"
echo "  2) bygg ny iOS build"
echo "  3) last opp til App Store Connect"
