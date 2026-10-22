#!/usr/bin/env python3
"""Inspect final release APK contents, preventing another JNI/regression false pass."""
import json
import re
import sys
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
original = json.loads((root / 'assets/data/recipes_ar.json').read_text(encoding='utf-8'))
saudi = json.loads((root / 'assets/data/saudi_phase1_recipes.json').read_text(encoding='utf-8'))
phase2 = json.loads((root / 'assets/data/saudi_phase2_recipes.json').read_text(encoding='utf-8'))
recipes = original + saudi + phase2
photos = sorted((root / 'assets/photos').glob('*.webp')) + sorted((root / 'assets/photos').glob('*.jpg'))
assert len(recipes) == 188
assert len({r['id'] for r in recipes}) == 188
assert len(list((root / 'assets/photos').glob('*.webp'))) == 168
assert all((root / 'assets/photos' / (r['id'] + '.jpg')).is_file() for r in phase2)
lock = (root / 'pubspec.lock').read_text(encoding='utf-8')
m = re.search(r'^  shared_preferences_android:\n(?:(?: {4,}.*)\n)*?    version: "([^"]+)"', lock, re.M)
assert m and m.group(1) == '2.4.28', 'Unsafe native JNI storage bridge version'
for raw in sys.argv[1:]:
    p = Path(raw)
    with zipfile.ZipFile(p) as apk:
        assert apk.testzip() is None, f'Corrupted APK {p}'
        names = set(apk.namelist())
        assert 'assets/flutter_assets/assets/data/recipes_ar.json' in names
        embedded = json.loads(apk.read('assets/flutter_assets/assets/data/recipes_ar.json'))
        assert embedded == original, 'APK original recipes differ from source'
        assert json.loads(apk.read('assets/flutter_assets/assets/data/saudi_phase1_recipes.json')) == saudi, 'APK Saudi phase1 recipes differ from source'
        assert json.loads(apk.read('assets/flutter_assets/assets/data/saudi_phase2_recipes.json')) == phase2, 'APK Saudi phase2 recipes differ from source'
        assert all('assets/flutter_assets/' + str(f.relative_to(root)) in names for f in photos)
        dexes = [n for n in names if re.fullmatch(r'classes\d*\.dex', n)]
        assert dexes, 'No Android DEX found'
        for d in dexes:
            dex = apk.read(d)
            for marker in (b'SharedPreferencesApiRegistrar', b'SharedPreferencesAsyncApiRegistrar'):
                assert marker not in dex, (p, d, 'JNI registrar unexpectedly present', marker)
        if 'arm64' in p.name:
            assert 'lib/arm64-v8a/libapp.so' in names
        if 'x86_64' in p.name:
            assert 'lib/x86_64/libapp.so' in names
    print(f'PASS: {p.name} stores 188 exact recipes, 188 local image files, legacy Android bridge 2.4.28')
