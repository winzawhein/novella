#!/usr/bin/env bash
set -euo pipefail

# Keep each supported CPU in its own APK instead of shipping three engines.
# Usage: bash tool/build-small-apk.sh --dart-define-from-file=/path/config.json
# Or pass the same --dart-define arguments used for your normal release build.
if [[ $# -eq 0 ]]; then
  echo 'Pass your Supabase --dart-define arguments or --dart-define-from-file config.' >&2
  exit 1
fi
cd "$(dirname "$0")/.."
flutter build apk --release --split-per-abi --tree-shake-icons "$@"
echo 'Most modern phones: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk'
echo 'Older 32-bit phones: build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk'
ls -lh build/app/outputs/flutter-apk/app-*-release.apk
