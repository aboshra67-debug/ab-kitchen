# AB Kitchen — V0.3 Warm identity Safe Patch

Based on verified GitHub V0.2.2 commit `724eb4272e39dfa67ada606f160ea7571bbf5dc6`.

## UI changes only
- Bundles the user-approved warm red/orange AB Kitchen logo as a compact optimized local JPG; original generated brand board is archived elsewhere.
- Adds platform launcher icons through flutter_launcher_icons after project generation in CI.
- Adds shared `KitchenBrand`, `BrandLogo`, `BrandIntro`, `BrandSectionTitle` widgets.
- Applies color scheme + brand logo to application shell and navigation.
- Unifies header layout on home/pantry/planner/shopping/assistant/settings; adds decorative treatment to recipe detail and cooking step.
- Polishes recipe card identity, weekly planning days and shopping progress bar.
- Dark mode remains available; pink/dark/children theme selector postponed as requested.
- Bumps Flutter package version to `0.3.0+3` and updates CI artifact name.

## Preserved
- **No recipe JSON changes**, still 30 recipes, eight cuisines.
- No change to persistence keys, migrations, shopping algorithms, planner data, TTS, or timer logic.
- Local offline recipe text remains bundled. **Remote audio/video/photo automatic persistent download is not yet implemented**.
- No deletion of functioning modules, user data or tests.

## Verification
Run `python tools/preflight.py` (basic static checks), `flutter analyze`, `flutter test`, `flutter build apk --debug`, and `flutter build ios --simulator --debug` in GitHub Actions. Report separately the actual results.