#!/usr/bin/env bash
# Release IPA for App Store Connect / TestFlight (run on macOS with Xcode installed).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: iOS release builds require macOS with Xcode."
  exit 1
fi

if [[ ! -f "ios/Runner/GoogleService-Info.plist" ]]; then
  echo "ERROR: ios/Runner/GoogleService-Info.plist not found."
  echo "Register the iOS app in Firebase (bundle ID com.thebabyland), then run:"
  echo "  dart pub global activate flutterfire_cli"
  echo "  flutterfire configure --project=thebabyland-6db6d --platforms=ios,android"
  exit 1
fi

echo "Installing CocoaPods dependencies..."
pushd ios >/dev/null
pod install
popd >/dev/null

FLUTTER_ARGS=(
  build ipa
  --release
  --no-tree-shake-icons
  --export-options-plist=ios/ExportOptions.plist
  --dart-define=API_BASE_URL=http://164.52.197.176/api/v1
  --dart-define=API_ROOT_URL=http://164.52.197.176/api
  --dart-define=FIREBASE_FORCE_RECAPTCHA=false
  --dart-define=APP_BUILD_TAG=appstore-v1
  --dart-define=FIREBASE_APP_CHECK_ENABLED=false
)

echo "flutter ${FLUTTER_ARGS[*]}"
flutter "${FLUTTER_ARGS[@]}"

IPA_DIR="$ROOT/build/ios/ipa"
echo ""
echo "IPA ready for Transporter / App Store Connect:"
ls -1 "$IPA_DIR"/*.ipa 2>/dev/null || echo "  (check $IPA_DIR)"
echo ""
echo "Upload with Apple Transporter or: xcrun altool --upload-app -f <path>.ipa -t ios -u <apple-id>"
