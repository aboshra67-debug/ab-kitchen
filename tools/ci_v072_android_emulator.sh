#!/usr/bin/env bash
# Executed as ONE bash script from reactivecircus Android emulator runner.
# Verifies SharedPreferences native bridge and all 148 recipes in release mode.
set -euo pipefail
APK="build/app/outputs/flutter-apk/app-x86_64-release.apk"
test -s "$APK"
adb install -r "$APK"
adb logcat -c
adb shell am start -W -n com.absoftware.ab_kitchen/.MainActivity
READY=0
for attempt in $(seq 1 45); do
  if adb logcat -d | grep -Fq 'AB_KITCHEN_STARTUP_READY recipes=148'; then
    READY=1
    break
  fi
  sleep 2
done
if [ "$READY" -ne 1 ]; then
  echo "::error::Release app did not confirm SharedPreferences and 148 recipe startup"
  adb logcat -d | grep -E 'NoSuchMethodError|PlatformException|AB_KITCHEN| E flutter' | tail -90 || true
  exit 1
fi
if adb logcat -d | grep -Fq 'SharedPreferencesApiRegistrar;.getAll'; then
  echo "::error::Original SharedPreferences JNI error still appears"
  exit 1
fi
echo "PASS: release APK launched on Android 35 emulator, SharedPreferences ready, 148 recipes loaded"
