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
mkdir -p release/screenshots/6.1-inch release/screenshots/6.3-inch release/screenshots/6.5-inch release/screenshots/6.9-inch
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

echo "==> Done"
magick identify release/screenshots/*/*.png release/social-card.png release/icon/AppIcon-1024.png
