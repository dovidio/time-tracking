#!/usr/bin/env bash
#
# Regenerate every release image from the SVG sources.
#
# Usage: Scripts/render-assets.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p docs/assets
mkdir -p release/screenshots/6.1-inch release/screenshots/6.3-inch release/screenshots/6.5-inch release/screenshots/6.9-inch release/header
mkdir -p release/icon

render() {
  local svg="$1" out="$2" width="$3" height="$4"
  rsvg-convert -w "$width" -h "$height" "$svg" -o "$out"
  # App Store screenshots must not carry an alpha channel.
  magick "$out" -background white -alpha remove -alpha off "$out"
}

echo "==> Screenshots"
for pair in today:01-today history:02-history day-editor:03-day-editor settings:04-settings; do
  src="${pair%%:*}"
  dst="${pair##*:}"
  render "Design/screens/$src.svg" "docs/assets/$src.png" 1170 2532
  render "Design/screens/$src.svg" "release/screenshots/6.1-inch/$dst.png" 1179 2556
  render "Design/screens/$src.svg" "release/screenshots/6.3-inch/$dst.png" 1206 2622
  render "Design/screens/$src.svg" "release/screenshots/6.5-inch/$dst.png" 1284 2778
  render "Design/screens/$src.svg" "release/screenshots/6.9-inch/$dst.png" 1320 2868
done

echo "==> App icon"
cp "TimeTracker/Assets.xcassets/AppIcon.appiconset/AppIcon.png" "release/icon/AppIcon-1024.png"

echo "==> Social card"
rsvg-convert -w 1280 -h 640 Design/social-card-bg.svg -o "$TMP/bg.png"

magick -size 112x112 xc:none -fill white -draw "roundrectangle 0,0 111,111 26,26" "$TMP/mask-icon.png"
magick docs/assets/icon.png -resize 112x112! "$TMP/icon.png"
magick "$TMP/icon.png" "$TMP/mask-icon.png" -alpha off -compose CopyOpacity -composite "$TMP/icon-round.png"

magick -size 258x560 xc:none -fill white -draw "roundrectangle 0,0 257,559 30,30" "$TMP/mask-phone.png"
magick docs/assets/today.png -resize 258x560! "$TMP/phone.png"
magick "$TMP/phone.png" "$TMP/mask-phone.png" -alpha off -compose CopyOpacity -composite "$TMP/phone-round.png"

magick "$TMP/bg.png" \
  "$TMP/icon-round.png" -geometry +80+80 -composite \
  "$TMP/phone-round.png" -geometry +950+40 -composite \
  -stroke '#FFFFFF2E' -strokewidth 1.5 -fill none -draw "roundrectangle 950,40 1208,600 30,30" \
  docs/assets/social-card.png

magick docs/assets/social-card.png -background white -alpha remove -alpha off docs/assets/social-card.png
cp docs/assets/social-card.png release/social-card.png

echo "==> Product page headers"

rounded() {
  local src="$1" width="$2" height="$3" radius="$4" out="$5"
  magick -size "${width}x${height}" xc:none -fill white \
    -draw "roundrectangle 0,0 $(($width - 1)),$(($height - 1)) $radius,$radius" "$TMP/mask.png"
  magick "$src" -resize "${width}x${height}!" "$TMP/img.png"
  magick "$TMP/img.png" "$TMP/mask.png" -alpha off -compose CopyOpacity -composite "$out"
}

# 21:9, 3840 x 1646
rsvg-convert -w 3840 -h 1646 Design/header-21x9-bg.svg -o "$TMP/h21.png"
rounded docs/assets/icon.png 220 220 50 "$TMP/h21-icon.png"
rounded docs/assets/today.png 620 1340 70 "$TMP/h21-phone.png"
magick "$TMP/h21.png" \
  "$TMP/h21-icon.png" -geometry +420+540 -composite \
  "$TMP/h21-phone.png" -geometry +2820+140 -composite \
  -stroke '#FFFFFF2E' -strokewidth 2 -fill none -draw "roundrectangle 2820,140 3440,1480 70,70" \
  -background white -alpha remove -alpha off release/header/header-21x9-3840x1646.png

# 16:9, 5244 x 2950
rsvg-convert -w 5244 -h 2950 Design/header-16x9-bg.svg -o "$TMP/h169.png"
rounded docs/assets/icon.png 320 320 72 "$TMP/h169-icon.png"
rounded docs/assets/today.png 1050 2275 120 "$TMP/h169-phone.png"
magick "$TMP/h169.png" \
  "$TMP/h169-icon.png" -geometry +600+1000 -composite \
  "$TMP/h169-phone.png" -geometry +3650+337 -composite \
  -stroke '#FFFFFF2E' -strokewidth 3 -fill none -draw "roundrectangle 3650,337 4700,2612 120,120" \
  -background white -alpha remove -alpha off release/header/header-16x9-5244x2950.png

echo "==> Done"
magick identify release/screenshots/*/*.png release/header/*.png release/social-card.png release/icon/AppIcon-1024.png
