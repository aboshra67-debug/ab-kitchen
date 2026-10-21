# AB Kitchen — permanent Android release signing (v1)

Canonical application ID: `com.absoftware.ab_kitchen`

Canonical certificate SHA-256:
`adabc03b93b62a960e573c5c99102776d8c725a1bc039ce2b3b0cf59d1aa5fe0`

Production key alias: `ab_kitchen` (RSA 3072).
Production private keystore: **NOT IN GIT**, backed up in private ChatGPT Library:
`/AB Kitchen/PRIVATE SIGNING/AB_Kitchen_PERMANENT_SIGNING_ONE_TIME_PRIVATE_BACKUP.zip`.
That private ZIP includes the password-protected PKCS12 keystore and its recovery details; do not copy it into source ZIPs or CI artifacts.

## Non-negotiable release procedure
1. Use the same package ID and the exact original production PKCS12 key for all future AB Kitchen releases. Increment pubspec version / Android versionCode when releasing a new version.
2. Do not ship GitHub runner debug-signed APKs as updates. Flutter's generated Android release configuration often signs with a per-run Debug key, which changes. Such files are **only test artifacts**.
3. Compile and test the unmodified Flutter project; verify that recipes, offline photos and shared_preferences load correctly.
4. Re-sign a zipaligned APK with the persistent production keystore via Android SDK `apksigner`. Verify v2/v3, and **strictly compare** release certificate SHA-256 to the canonical fingerprint above before distributing.
5. For automated signing in GitHub, configure three protected Actions repository secrets once: `AB_KITCHEN_RELEASE_KEYSTORE_B64` (base64 of full .p12 file), `AB_KITCHEN_RELEASE_KEYSTORE_PASSWORD` and `AB_KITCHEN_RELEASE_KEY_ALIAS` (ab_kitchen). NEVER place secret values directly in workflow files. Use `.github/workflows/ab_kitchen_production_release.yml`, which fails closed if secrets are missing.
6. Alternatively, download test APK from CI and re-sign it privately with the backed-up key using official apksigner outside GitHub. Check the SHA-256 fingerprint before delivery.

## Migration caveat
The previously distributed V0.7.2 through V0.7.4 TEST_SIGNED APKs used ephemeral GitHub Android Debug signing. Their private keys are not available. A device installation carrying another certificate cannot be updated with this new production signing key just by changing the app version. If it has irreplaceable local user data, back that data up BEFORE any uninstall or package replacement. After a one-time switch to the production-signed APK, subsequent APK updates will work normally with the same fingerprint and increasing versionCodes.

Do not put private keys, keystore passwords or password recovery documents in repository commits, issue comments, public release assets, screenshot assets or Safe Source packages.
