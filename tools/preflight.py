#!/usr/bin/env python3
"""Dependency-free safety checks; not a substitute for Flutter analyze/test/build."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
original = json.loads((root / 'assets/data/recipes_ar.json').read_text(encoding='utf-8'))
saudi_phase1 = json.loads((root / 'assets/data/saudi_phase1_recipes.json').read_text(encoding='utf-8'))
saudi_phase2 = json.loads((root / 'assets/data/saudi_phase2_recipes.json').read_text(encoding='utf-8'))
saudi_phase3 = json.loads((root / 'assets/data/saudi_phase3_recipes.json').read_text(encoding='utf-8'))
assert len(original) == 148 and len(saudi_phase1) == 20 and len(saudi_phase2) == 20 and len(saudi_phase3) == 20
recipes = original + saudi_phase1 + saudi_phase2 + saudi_phase3
syrian_phase1 = json.loads((root / 'assets/data/syrian_phase1_recipes.json').read_text(encoding='utf-8'))
assert len(syrian_phase1) == 20
recipes += syrian_phase1
syrian_phase2 = json.loads((root / 'assets/data/syrian_phase2_recipes.json').read_text(encoding='utf-8'))
assert len(syrian_phase2) == 20
recipes += syrian_phase2
assert isinstance(recipes, list) and len(recipes) == 248
ids = [r['id'] for r in recipes]
assert len(ids) == len(set(ids))
assert sum(r.get('collection') == 'blaban_inspired' for r in recipes) == 14
assert sum(r['country'] == 'eg' for r in recipes) == 123
assert sum(r['country'] == 'sa' for r in recipes) == 65
assert len({r['category'] for r in recipes if r['country'] == 'eg'}) == 11
assert len({r['name'].strip() for r in recipes if r['country'] == 'eg'}) == 123
assert all(len(r.get('topping_ids', [])) >= 4 for r in recipes if r.get('collection') == 'blaban_inspired')
assert {'eg', 'sa', 'sy'}.issubset({r['country'] for r in recipes})
assert len({r['country'] for r in recipes}) == 8
assert sum(r['country'] == 'sy' for r in recipes) == 45
for recipe in recipes:
    assert recipe['servings'] > 0 and recipe['minutes'] > 0
    assert len(recipe['steps']) >= 3
    assert recipe['ingredients']
    assert all(i['name'].strip() and i['unit'].strip() and
               isinstance(i['quantity'], (int, float)) and i['quantity'] > 0
               for i in recipe['ingredients'])

paths = sorted((root / 'lib').rglob('*.dart'))
assert len(paths) >= 13
for p in paths:
    body = p.read_text(encoding='utf-8')
    for imp in re.findall(r"^import '([^']+)'\s*;", body, re.MULTILINE):
        if imp.startswith(('../', './')) or ('/' not in imp and ':' not in imp):
            assert (p.parent / imp).resolve().is_file(), (str(p), imp)
for expected in (
    '.github/workflows/flutter_ci.yml', 'test/recipe_test.dart',
    'test/smoke_widget_test.dart', 'test/dessert_catalog_test.dart', 'tools/verify_and_build.sh',
):
    assert (root / expected).is_file(), expected
pubspec = (root / 'pubspec.yaml').read_text(encoding='utf-8')
assert 'version: 0.8.1+19' in pubspec
assert 'assets/photos/' in pubspec
for photo in (root/'assets/photos').glob('*.webp'):
    assert photo.stat().st_size > 3000, str(photo)
assert len(list((root/'assets/photos').glob('*.webp'))) == 168
assert all((root/'assets/photos'/(r['id']+'.jpg')).is_file() for r in saudi_phase2)
assert all((root/'assets/photos'/(r['id']+'.jpg')).is_file() for r in saudi_phase3)
assert all((root/'assets/photos'/(r['id']+'.jpg')).is_file() for r in syrian_phase1 + syrian_phase2)
assert (root/'assets/photos/sa_sago.jpg').stat().st_size > 60000
assert (root/'assets/photos/eg_fino_bread.jpg').is_file(), 'Missing Egyptian fino image'
# Phase 3 images are original generated illustrations. Earlier photos are retained.
assert all((root/'assets/photos'/(r['id']+'.jpg')).is_file() for r in saudi_phase2)
assert all((root/'assets/photos'/(r['id']+'.jpg')).is_file() for r in saudi_phase2)
assert 'assets/data/recipes_ar.json' in pubspec and 'assets/branding/ab_kitchen_logo.jpg' in pubspec
assert 'shared_preferences:' in pubspec and 'flutter_tts:' in pubspec
assert 'shared_preferences_android: 2.4.28' in pubspec, 'Unsafe JNI Android storage plugin version'
logo = root / 'assets/branding/ab_kitchen_logo.jpg'
assert logo.is_file() and logo.stat().st_size > 10000
assert (root / 'assets/branding/ab_kitchen_app_icon.png').is_file()
assert 'flutter_launcher_icons:' in pubspec
assert (root / 'lib/branding/brand_widgets.dart').is_file()
print(f'PASS: {len(recipes)} recipes; 8 cuisines; {len(paths)} Dart files; local imports resolve; CI/test/build scripts present.')
print('NOT TESTED: Dart parsing, Flutter static analysis, Flutter widget execution, Android/iOS binaries.')