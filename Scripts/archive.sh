#!/usr/bin/env bash
#
# Archive and export a Release build for the App Store.
#
# Prerequisites (see APPSTORE.md):
#   - Paid Apple Developer Program membership
#   - Apple Distribution certificate in the keychain
#   - App record created in App Store Connect
#   - Xcode signed in with the right account
#
# Usage:
#   TEAM_ID=XXXXXXXXXX Scripts/archive.sh
#
# The IPA lands in build/export/. Upload it with Xcode Organizer
# (Window → Organizer → Distribute App) or altool.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

: "${TEAM_ID:?Set TEAM_ID to your Apple Developer team identifier}"

BUILD_DIR="$ROOT/build"
ARCHIVE="$BUILD_DIR/TimeTracker.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
EXPORT_OPTIONS="$BUILD_DIR/ExportOptions.plist"

mkdir -p "$BUILD_DIR"

echo "==> Regenerating project"
xcodegen generate

echo "==> Archiving with team $TEAM_ID"
xcodebuild \
  -project TimeTracker.xcodeproj \
  -scheme TimeTracker \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  -allowProvisioningUpdates \
  archive

cat > "$EXPORT_OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>teamID</key>
	<string>$TEAM_ID</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>uploadSymbols</key>
	<true/>
	<key>destination</key>
	<string>export</string>
</dict>
</plist>
PLIST

echo "==> Exporting IPA"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -exportPath "$EXPORT_DIR" \
  -allowProvisioningUpdates

IPA="$(find "$EXPORT_DIR" -maxdepth 1 -name '*.ipa' | head -1)"

echo
echo "IPA: $IPA"
echo
echo "Upload it with:"
echo "  Xcode → Window → Organizer → Distribute App → App Store Connect → Upload"
echo "or, with an App Store Connect API key:"
echo "  xcrun altool --upload-app -f \"$IPA\" -t ios --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>"
