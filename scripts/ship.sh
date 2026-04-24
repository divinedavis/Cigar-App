#!/usr/bin/env bash
# Bumps CFBundleVersion, regenerates the Xcode project with xcodegen,
# archives, exports, and uploads Maduro to TestFlight.
#
# Runs after every code change so the latest state is always testable.
# Requires scripts/asc-config.env (gitignored) with real ASC credentials.

set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

if [[ ! -f scripts/asc-config.env ]]; then
    echo "error: scripts/asc-config.env missing. Copy from .example and fill in real values." >&2
    exit 1
fi

# shellcheck disable=SC1091
source scripts/asc-config.env

PROJECT="Maduro.xcodeproj"
SCHEME="Maduro"
PBXPROJ="$PROJECT/project.pbxproj"
ARCHIVE="build/Maduro.xcarchive"
EXPORT_DIR="build/export"
IPA="$EXPORT_DIR/Maduro.ipa"

# 0. Bump CURRENT_PROJECT_VERSION in project.yml (source of truth) so
# xcodegen carries the new value into the generated pbxproj. Otherwise
# xcodegen would reset it back to project.yml's value on every run.
current=$(grep -E '^\s*CURRENT_PROJECT_VERSION:' project.yml | awk -F': ' '{print $2}' | tr -d ' "')
next=$((current + 1))
echo "==> bumping build $current -> $next"
sed -i '' -E "s/^([[:space:]]*CURRENT_PROJECT_VERSION:)[[:space:]]*[0-9]+/\1 $next/" project.yml

# 1. Regenerate project from project.yml.
if command -v xcodegen >/dev/null 2>&1; then
    echo "==> regenerating Xcode project from project.yml"
    xcodegen generate
else
    # Fall back to editing pbxproj in place if xcodegen isn't available.
    sed -i '' "s/CURRENT_PROJECT_VERSION = $current;/CURRENT_PROJECT_VERSION = $next;/g" "$PBXPROJ"
fi

# 2. Archive.
echo "==> archiving"
rm -rf build
mkdir -p build
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE" \
    -allowProvisioningUpdates \
    archive

# 3. Export the IPA.
echo "==> exporting IPA"
xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist ExportOptions.plist \
    -allowProvisioningUpdates

# 4. Upload to TestFlight.
echo "==> uploading to TestFlight"
xcrun altool \
    --upload-app \
    -f "$IPA" \
    -t ios \
    --apiKey "$ASC_KEY_ID" \
    --apiIssuer "$ASC_ISSUER_ID"

echo "==> done. build $next uploaded; processing takes a few minutes before it's available in TestFlight."
