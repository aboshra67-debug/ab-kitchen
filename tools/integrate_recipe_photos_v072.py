#!/usr/bin/env python3
"""AB Kitchen V0.7.2: reproducible safe photo integration and Android/source QA.
Creates new WebP files only; never overwrites old photos or edits recipe data.
"""
from __future__ import annotations
import hashlib,json,os,re,subprocess,sys,zipfile
from pathlib import Path
from PIL import Image,ImageOps

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'assets/photos_batch08_17'
DEST=ROOT/'assets/photos'
OUT=ROOT/'deliverables'
META=ROOT/'tools/photo_integration_v072_manifest.json'
BASE=ROOT/'assets/data/recipes_ar.json'
WIDGET=ROOT/'lib/widgets/recipe_photo.dart'
APK=OUT/'AB_Kitchen_V072_148_PHOTOS_ARM64_TEST_ONLY.apk'
SOURCE=OUT/'AB_Kitchen_V072_148_PHOTOS_SAFE_SOURCE.zip'
AUDIT=OUT/'AB_Kitchen_V072_148_PHOTOS_AUDIT.json'
def sha(raw):return hashlib.sha256(raw).hexdigest()
def get_photos():
    text=WIDGET.read_text(encoding='utf-8')
    match=re.search(r'static const picturedRecipes = <String>\{(.*?)\};',text,re.S)
    assert match,'Photo widget mapping not found'
    ids=re.findall(r"'([a-z0-9_]+)'",match.group(1))
    assert len(ids)==148 and len(set(ids))==148,f'Unmatched or repeated ID ({len(ids)})'
    assert 'eg_koshari_hero.webp' in text
    return set(ids)
def pack_safe_source():
    # Include every tracked source file and generated WebP after git add, except
    # delivery archives, platform boilerplate, local secrets and build files.
    subprocess.run(['git','add','assets/photos/'],cwd=ROOT,check=True)
    tracked=subprocess.check_output(['git','ls-files','-z'],cwd=ROOT).split(b'\x00')
    selected=[]
    for item in tracked:
        if not item:continue
        rel=item.decode('utf-8')
        if rel.startswith(('deliverables/','android/','ios/','build/','.dart_tool/','.git/')):continue
        if re.search(r'(?:\.jks|\.keystore|\.p12|\.p8|\.env(?:\..*)?|key\.properties)$',rel,re.I):continue
        if (ROOT/rel).is_file():selected.append(rel)
    assert len(selected)==len(set(selected))
    assert sum(1 for s in selected if s.startswith('assets/photos/') and s.endswith('.webp'))==149
    assert 'pubspec.yaml' in selected and 'assets/data/recipes_ar.json' in selected
    assert 'lib/widgets/recipe_photo.dart' in selected
    with zipfile.ZipFile(SOURCE,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
        for rel in sorted(selected):z.write(ROOT/rel,arcname=rel)
    with zipfile.ZipFile(SOURCE) as z:
        assert z.testzip() is None
        assert len([x for x in z.namelist() if x.startswith('assets/photos/') and x.endswith('.webp')])==149
def dhash(image):
    gray=ImageOps.grayscale(image).resize((9,8),Image.Resampling.LANCZOS)
    a=list(gray.getdata())
    return sum(1<<(r*8+c) for r in range(8) for c in range(8) if a[r*9+c]>a[r*9+c+1])
def prepare():
    OUT.mkdir(exist_ok=True)
    data=json.loads(META.read_text('utf-8'))
    assert data['images_added']==17 and data['photos_total']==148
    expected=set(data['new_recipe_ids']); assert len(expected)==17
    recipes=json.loads(BASE.read_text('utf-8'))
    known={r['id'] for r in recipes}
    assert len(known)==len(recipes)==148 and expected.issubset(known)
    old={p.stem for p in DEST.glob('*.webp')}
    assert len(old)==132 and 'eg_koshari_hero' in old
    assert not (expected&old),f'Existing files must never be overwritten: {expected&old}'
    assert len(get_photos())==148 and get_photos()==known
    files=list(SRC.glob('*.jpg'))
    assert len(files)==17 and {p.stem for p in files}==expected
    records=[]; seen_hashes={}; perceptual=[]
    for rid in sorted(expected):
        src=SRC/(rid+'.jpg')
        raw=src.read_bytes()
        assert 3000<len(raw)<8_000_000,f'Image bytes outside safe range: {rid}'
        checksum=sha(raw)
        assert checksum not in seen_hashes,f'Identical image reused: {rid} and {seen_hashes[checksum]}'
        seen_hashes[checksum]=rid
        with Image.open(src) as im:im.verify()
        with Image.open(src) as im:
            assert im.format=='JPEG' and im.width>=480 and im.height>=350
            width,height=im.size
            perceptual.append((rid,dhash(im)))
            rendered=ImageOps.exif_transpose(im).convert('RGB')
            rendered.thumbnail((1152,1152),Image.Resampling.LANCZOS)
            target=DEST/(rid+'.webp')
            assert not target.exists(),f'No overwrites allowed: {target}'
            temporary=target.with_name(target.name+'.pending')
            rendered.save(temporary,'WEBP',quality=86,method=5)
            assert 3000<temporary.stat().st_size<500_000,f'Unexpected WebP output size: {rid}'
            with Image.open(temporary) as chk:chk.verify()
            os.replace(temporary,target)
        records.append({'id':rid,'jpg_bytes':len(raw),'jpg_sha256':checksum,'jpeg_dimensions':[width,height],
                        'webp_bytes':target.stat().st_size,'webp_sha256':sha(target.read_bytes()),
                        'webp_asset':'assets/photos/'+rid+'.webp'})
    flagged=[]
    for i,(a,ph_a) in enumerate(perceptual):
        for b,ph_b in perceptual[i+1:]:
            n=(ph_a^ph_b).bit_count()
            if n<=7:flagged.append({'a':a,'b':b,'similarity_hamming':n})
            assert n>2,f'Near identical photographs: {a} and {b}'
    allassets={p.stem for p in DEST.glob('*.webp')}
    assert len(allassets)==149 and allassets-{'eg_koshari_hero'}==known
    audit={'project':'AB Kitchen','version':'0.7.2+9','recipe_total':148,'images_new':17,'images_prior':131,
           'recipe_photos_offline':148,'webp_assets_including_koshari_hero':149,
           'new_image_details':records,'possible_visual_similarity_for_review':flagged,
           'all_old_images_retained':True,'no_recipe_data_modified':True,'no_other_modules_changed':True,
           'photo_type':'Individually generated realistic food illustrations, not original camera photos',
           'human_visual_approval':'Pending final user assessment; programmatic image validation passed'}
    AUDIT.write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('PASS: 148 mapped photos, 149 image assets, 17 new optimized WebP; no previous image removed.')
def finish():
    audit=json.loads(AUDIT.read_text('utf-8'))
    candidate=ROOT/'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk'
    assert candidate.is_file() and candidate.stat().st_size>3_000_000
    with zipfile.ZipFile(candidate) as apk:
        assert apk.testzip() is None
        items=set(apk.namelist())
        for rid in get_photos():
            assert f'assets/flutter_assets/assets/photos/{rid}.webp' in items, f'Photo not in APK: {rid}'
        assert 'assets/flutter_assets/assets/photos/eg_koshari_hero.webp' in items
    OUT.mkdir(exist_ok=True)
    APK.write_bytes(candidate.read_bytes())
    assert APK.stat().st_size<90_000_000,'APK too large for direct GitHub file delivery'
    pack_safe_source()
    audit['arm64_test_apk_sha256']=sha(APK.read_bytes())
    audit['arm64_test_apk_bytes']=APK.stat().st_size
    audit['safe_source_sha256']=sha(SOURCE.read_bytes())
    audit['safe_source_bytes']=SOURCE.stat().st_size
    audit['apk_variant']='Android ARM64 release-optimized, but signed with runner DEBUG key; not a production release'
    audit['signed_key_caveat']='Might NOT upgrade prior APK signed under another debug key; do not uninstall apps with local data'
    audit['files_in_apk_verified']=149
    AUDIT.write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('VERIFIED DELIVERABLES',APK.stat().st_size,SOURCE.stat().st_size)
if __name__=='__main__':
    if '--finish' in sys.argv:finish()
    else:prepare()
