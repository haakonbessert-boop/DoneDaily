#!/usr/bin/env bash
set -euo pipefail

PROJECT_PATH="$(cd "$(dirname "$0")/.." && pwd)/DoneDaily.xcodeproj"
SCHEME="DoneDaily"
ARCHIVE_PATH="$(cd "$(dirname "$0")/.." && pwd)/build/DoneDaily.xcarchive"
EXPORT_PATH="$(cd "$(dirname "$0")/.." && pwd)/build/export"
EXPORT_OPTIONS_PLIST="$(cd "$(dirname "$0")/.." && pwd)/ExportOptions.plist"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_PATH" \
  archive

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

echo "Archive und Export abgeschlossen: $EXPORT_PATH"
