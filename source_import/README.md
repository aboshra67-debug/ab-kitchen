# Source import (one-time)

This directory receives the existing ChatGPT-produced safe source archive. Upload **AB_Kitchen_Flutter_V0_2_SAFE_SOURCE.zip** here without renaming it.

GitHub Actions workflow **Import AB Kitchen source ZIP and build** verifies SHA-256 `3cc7359b2d3ff0931cb3cb5dc783e39a092584892b350e5a7268271a99c84e8c`, checks ZIP integrity and path safety, extracts the Flutter code, runs `flutter analyze`, `flutter test` and Android `flutter build apk --debug`. APK upload happens only after all checks pass.

On successful checks, the workflow commits source files to the repository while preserving prior files. No existing project code is deleted. The generated debug APK is only for testing, and iOS requires macOS runners and Apple signing for device distribution.
