#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v flutter >/dev/null 2>&1; then
  echo 'ERROR: Flutter SDK is not installed on this machine.' >&2
  exit 2
fi
flutter create --project-name ab_kitchen --org com.absoftware --platforms=android,ios .
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
printf '\nBuild success: %s\n' "$PWD/build/app/outputs/flutter-apk/app-debug.apk"