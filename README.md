# AB Kitchen — مطبخ العالم

Flutter app for Android and iOS, Arabic RTL. Initial V0.2 includes 30 sample recipes across eight cuisines, serving-size adjustment, guided cooking steps with device TTS, shopping basket, pantry suggestions, weekly planner and local assistant.

## Import current V0.2 source
The original V0.2 project ZIP is distributed in the ChatGPT conversation. To import it without manually copying ~25 files:
1. Open [source_import](./source_import) in GitHub.
2. Choose **Add file > Upload files** and upload `AB_Kitchen_Flutter_V0_2_SAFE_SOURCE.zip` without renaming it.
3. Commit directly to `main`.
4. Visit [Actions](../../actions). The **Import AB Kitchen source ZIP and build** workflow verifies the exact package SHA-256, safely extracts Dart/data files, runs Flutter static analysis and tests and builds an Android debug APK.
5. Download the `AB-Kitchen-V0.2-Android-DEBUG` artifact only if the workflow succeeds. iOS simulator check is in the separate Flutter CI workflow.

The importer protects existing repository files and refuses a mismatched source ZIP. A Flutter debug APK is **not a production signed release**.

## Offline behavior
V0.2 recipes and their text data are bundled locally and available without network access. It does **not** yet download/cache remote audio, photos or video. Permanent media caching requires a future dedicated module and device testing.

## Current status
This repository contains import/build workflows but **the source archive has not been imported yet**. No APK build success or iOS build has been verified. No signing keys or secrets are stored in this repository.
