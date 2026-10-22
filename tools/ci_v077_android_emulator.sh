#!/usr/bin/env bash
# Android 35 x86_64 release smoke test. Runs actual installed release binary, twice.
set -euo pipefail
APK=build/app/outputs/flutter-apk/app-x86_64-release.apk
PACKAGE=com.absoftware.ab_kitchen
mkdir -p deliverables
adb install -r "$APK"
for boot in 1 2; do
  adb shell am force-stop "$PACKAGE" || true
  adb logcat -c
  adb shell am start -W -n "$PACKAGE/.MainActivity"
  READY=0
  for _ in $(seq 1 75); do
    if adb logcat -d | grep -Fq 'AB_KITCHEN_STARTUP_READY recipes=188'; then
      READY=1
      break
    fi
    sleep 2
  done
  if [ "$READY" -ne 1 ]; then
    echo "::error::Android release startup $boot did not load preferences and 188 recipes"
    adb logcat -d | grep -E 'NoSuchMethodError|PlatformException|AB_KITCHEN|E/flutter| E flutter' | tail -80 || true
    exit 1
  fi
  if adb logcat -d | grep -Eq 'SharedPreferences(Api|AsyncApi)Registrar|NoSuchMethodError'; then
    echo "::error::Native preferences error in Android release startup $boot"
    exit 1
  fi
  if ! adb shell pidof "$PACKAGE" >/dev/null; then
    echo "::error::Android process quit after startup $boot"
    exit 1
  fi
  adb exec-out screencap -p > "deliverables/AB_Kitchen_V077_emulator_boot_${boot}.png"
  echo "PASS: release boot $boot, SharedPreferences ready, 188 recipes loaded"
done
