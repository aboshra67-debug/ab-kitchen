#!/usr/bin/env python3
"""Inspect final release APK contents, preventing another JNI/regression false pass."""
import json
import re
import sys
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
recipes = json.loads((root / 'assets/data/recipes_ar.json').read_text(encoding='utf-8'))
photos = sorted((root / 'assets/photos').glob('*.webp'))
assert len(recipes) == 148
assert len({r['id'] for r in recipes}) == 148
assert len(photos) == 132
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
        assert embedded == recipes, 'APK recipe data differs from source'
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
    print(f'PASS: {p.name} stores 148 exact recipes, 132 local image files, legacy Android bridge 2.4.28')
