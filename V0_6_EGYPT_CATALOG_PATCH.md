# V0.6 — Egypt Catalogue Safe Patch

- Base: AB Kitchen V0.5 / GitHub main commit `87c63d591473a51e5b09d6398f30d58e5c2f1def`.
- Content: 104 new Egyptian recipes, now 123 Egyptian and 148 total. 11 Egypt categories including existing 14 dessert catalogue families.
- Existing 44 recipes preserved byte-for-byte at the JSON-object level; no ID changes. Existing images and preferences untouched.
- UI: add Egypt featured entry, relevant country-specific categories, reset category on cuisine switch.
- Tests: add Egyptian counts and legacy ID tests; retain dessert + widget tests and strengthen preflight.
- Version `0.6.0+6`; CI artifact renamed. No new photos are claimed for unmatched dishes; no network permission introduced.
- Before public launch, validate cooking directions/quantities with cooks and food hygiene review, and obtain original high-quality dish-specific photos.