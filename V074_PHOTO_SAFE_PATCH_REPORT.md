# AB Kitchen V0.7.4+11 — 16-photo Safe Patch

- Previous baseline V0.7.3 (148 recipes, 131 registered photos, 132 WebP images including Koshari hero) preserved.
- Added 16 correctly named local WebP pictures for screenshot dishes; `eg_duqqa_alex` already had a picture and was preserved as-is.
- Post-patch: 148 recipes, 147 pictured recipes and 148 photo assets (including hero image). `eg_fino_bread` remains without a verified image.
- Source `assets/data/recipes_ar.json` unchanged byte for byte.
- Original `assets/data/licensed_photo_credits.json` unchanged. Newly generated images are original AI illustrations; provenance saved separately in `assets/data/generated_photo_audit_v074.json`.
- SharedPreferences Android 2.4.28 retained, no change to application ID, existing customer data, navigation, settings, or Android signing configuration.
- Added regression test, updated old photo coverage test, static preflight, and APK validation to match exact inventory.
- Image crops for 7 later dishes were taken from an original generated food grid and are usable at mobile card size; they may be less detailed than the 9 individually generated illustrations.
- Build and emulator testing must be performed in GitHub CI; no claim of APK production until successful.
