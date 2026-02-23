#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/DoneDaily.xcodeproj"
SCHEME="DoneDaily"
SIMULATOR_NAME=""
SIMULATOR_ID=""
OS_VERSION=""
DESTINATION=""
RESULT_BUNDLE="/tmp/donedaily-smoke-tests.xcresult"

run_xcodebuild() {
  if command -v xcbeautify >/dev/null 2>&1; then
    xcodebuild "$@" | xcbeautify
  else
    xcodebuild "$@"
  fi
}

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "xcodebuild is not usable. Select full Xcode first:"
  echo "sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

SIMULATOR_LINE="$(xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -showdestinations 2>/dev/null | rg -m1 'platform:iOS Simulator,.*name:iPhone' || true)"
if [[ -n "$SIMULATOR_LINE" ]]; then
  SIMULATOR_NAME="$(echo "$SIMULATOR_LINE" | sed -E 's/.*name:([^}]+).*/\1/' | xargs)"
  SIMULATOR_ID="$(echo "$SIMULATOR_LINE" | sed -E 's/.*id:([^,]+),.*/\1/' | xargs)"
  OS_VERSION="$(echo "$SIMULATOR_LINE" | sed -E 's/.*OS:([^,]+),.*/\1/' | xargs)"
  DESTINATION="platform=iOS Simulator,id=$SIMULATOR_ID"
fi

if [[ -z "$SIMULATOR_NAME" || -z "$SIMULATOR_ID" ]]; then
  echo "No available iPhone simulator found."
  exit 1
fi

echo "Using simulator: $SIMULATOR_NAME ($SIMULATOR_ID, iOS $OS_VERSION)"
echo "Resetting simulator state..."
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /usr/bin/xcrun simctl shutdown all || true
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /usr/bin/xcrun simctl erase all || true

echo "==> Build (Debug, Simulator)"
run_xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "$DESTINATION" \
  build

if xcodebuild -list -project "$PROJECT_PATH" | rg -q "DoneDailyTests"; then
  echo "==> Unit Tests"
  rm -rf "$RESULT_BUNDLE"
  run_xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -destination-timeout 60 \
    -parallel-testing-enabled NO \
    -maximum-concurrent-test-simulator-destinations 1 \
    -only-testing:DoneDailyTests \
    -skip-testing:DoneDailyUITests \
    -resultBundlePath "$RESULT_BUNDLE" \
    test
else
  echo "==> Test target not configured in project yet (skipped)."
fi

echo "Result bundle: $RESULT_BUNDLE"
echo "==> Smoke checks complete"
