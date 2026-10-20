#!/usr/bin/env python3
"""Safe, auditable, offline AB Kitchen V0.7.1 picture integration.

Only creates *missing* files under assets/photos and output deliverables.
Never alters existing images or recipe data, never touches persisted user data.
Image source branch is pinned in tools/photo_integration_v071_manifest.json.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import zipfile
from PIL import Image, ImageOps

ROOT=Path(__file__).resolve().parents[1]
PHOTOS=ROOT/"assets/photos"
MANIFEST=ROOT/"tools/photo_integration_v071_manifest.json"
DATA=ROOT/"assets/data/recipes_ar.json"
WIDGET=ROOT/"lib/widgets/recipe_photo.dart"
OUT=ROOT/"deliverables"
AUDIT=OUT/"AB_Kitchen_V071_91_Photos_Integration_Audit.json"
SOURCE_NAME="AB_Kitchen_V071_131_PHOTOS_SAFE_SOURCE.zip"
APK_NAME="AB_Kitchen_V071_131_PHOTOS_ANDROID_DEBUG.apk"
assert not ROOT.joinpath("assets/photos/eg_fino_bread.webp").exists(), "fino is awaiting separately verified source"

def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def mapped_ids():
    code=WIDGET.read_text(encoding="utf-8")
    match=re.search(r"static const picturedRecipes = <String>\{(.*?)\};",code,re.S)
    assert match,"RecipePhoto mapping vanished"
    values=re.findall(r"'([a-z0-9_]+)'",match.group(1))
    assert len(values)==len(set(values)),"Duplicate ID in dart photo mapping"
    assert "eg_koshari_hero.webp" in code,"Original koshari hero mapping changed"
    return set(values)

def prepare(source_dir: Path):
    OUT.mkdir(exist_ok=True)
    manifest=json.loads(MANIFEST.read_text(encoding="utf-8"))
    photos=manifest["photo_source_paths"]
    ids=manifest["photo_ids"]
    assert len(ids)==91 and len(set(ids))==91
    assert len(photos)==len(ids)==manifest["new_image_count"]
    assert len({p.rsplit("/",1)[-1] for p in photos})==91
    assert len(set(photos))==91
    assert all(re.fullmatch(r"assets/photos_batch0[1-7]/[a-z0-9_]+\.jpg",p) for p in photos)
    actual_ids={p.rsplit("/",1)[-1].removesuffix(".jpg") for p in photos}
    assert actual_ids==set(ids),"Manifest path and ID disagreement"
    recipes=json.loads(DATA.read_text(encoding="utf-8"))
    assert len(recipes)==148
    all_ids={r["id"] for r in recipes}
    assert len(all_ids)==148
    assert actual_ids.issubset(all_ids)
    original={p.stem for p in PHOTOS.glob("*.webp")}
    assert len(original)==41 and "eg_koshari_hero" in original,"Baseline image set changed"
    assert not actual_ids.intersection(original),"Never overwrite an existing photo"
    assert mapped_ids()==((original-{"eg_koshari_hero"}) | actual_ids),"Dart mapping does not match images"
    input_dir=source_dir.resolve()
    output_dir=PHOTOS.resolve()
    assert input_dir!=output_dir and input_dir.is_dir()
    image_audit=[]
    seen_hash={}
    for rel in photos:
        src=(input_dir/rel).resolve()
        assert src.is_relative_to(input_dir), "Untrusted input path"
        assert src.is_file(),f"Missing staged photo: {rel}"
        rid=src.stem
        dest=PHOTOS/(rid+".webp")
        assert not dest.exists(),f"Refusing overwrite: {dest}"
        blob=src.read_bytes()
        assert sha(blob) not in seen_hash,f"Duplicate source bytes: {rid} and {seen_hash[sha(blob)]}"
        seen_hash[sha(blob)]=rid
        assert len(blob)<8_000_000 and len(blob)>3000
        with Image.open(src) as preview:
            preview.verify()
        with Image.open(src) as opened:
            assert opened.format=="JPEG",f"Unexpected format: {src}"
            assert opened.width>=600 and opened.height>=400,src
            w,h=opened.size
            frame=ImageOps.exif_transpose(opened).convert("RGB")
            frame.thumbnail((1050,1050),Image.Resampling.LANCZOS)
            temp=dest.with_name(dest.name+".pending")
            frame.save(temp,"WEBP",quality=83,method=5)
            assert temp.stat().st_size>3000 and temp.stat().st_size<400_000, f"Image too large: {rid}"
            with Image.open(temp) as output:
                output.verify()
            os.replace(temp,dest)
        image_audit.append({"recipe_id":rid,"input":rel,
          "original_jpeg_sha256":sha(blob),"original_bytes":len(blob),
          "output":"assets/photos/"+rid+".webp",
          "webp_sha256":sha(dest.read_bytes()),"webp_bytes":dest.stat().st_size,
          "original_dimensions":[w,h]})
    assert len(image_audit)==91
    new=set(image_audit[i]["recipe_id"] for i in range(91))
    deployed={p.stem for p in PHOTOS.glob("*.webp")} - {"eg_koshari_hero"}
    assert len(deployed)==131 and mapped_ids()==deployed
    missing=sorted(all_ids-deployed)
    assert len(missing)==17 and "eg_fino_bread" in missing
    report={"project":"AB Kitchen","version":"0.7.1+8",
       "baseline_recipe_count":148,"original_bundled_recipe_photos":40,
       "new_bundled_photos":91,"total_pictured_recipes":131,
       "remaining_recipes_without_photos":17,"remaining_ids":missing,
       "source_branch":manifest["photo_source_ref"],
       "main_was_not_modified_by_this_workflow":True,
       "no_existing_images_replaced":True,"no_user_data_or_recipes_modified":True,
       "photo_type":"AI-generated photorealistic illustrations, not documentary photographs",
       "semantic_image_review":"Source batch images previously reviewed in batches; not all 91 underwent an independent expert food photo audit",
       "images":image_audit}
    AUDIT.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print("PHOTO SAFE PATCH PASS",len(image_audit),"new",len(deployed),"total; missing",missing)
    print("NEW WEBP TOTAL BYTES",sum(x["webp_bytes"] for x in image_audit))

def git_files():
    rows=subprocess.check_output(["git","ls-files","-z"],cwd=ROOT).split(b"\x00")
    for row in rows:
        if not row:continue
        rel=row.decode("utf-8")
        if rel.startswith(("android/","ios/","build/","deliverables/")):continue
        if not (ROOT/rel).is_file():continue
        yield rel

def package():
    OUT.mkdir(exist_ok=True)
    report=json.loads(AUDIT.read_text(encoding="utf-8"))
    assert report["new_bundled_photos"]==91 and report["total_pictured_recipes"]==131
    apk=ROOT/"build/app/outputs/flutter-apk/app-debug.apk"
    assert apk.is_file() and apk.stat().st_size>3_000_000,"Actual Android APK was not built"
    archive=zipfile.ZipFile(apk)
    content=archive.namelist()
    for rid in mapped_ids():
        expected=f"assets/flutter_assets/assets/photos/{rid}.webp"
        assert expected in content,f"APK lacks photo {rid}"
    archive.close()
    safe_source=OUT/SOURCE_NAME
    file_list=sorted(set(git_files()))
    assert len([x for x in file_list if x.startswith("assets/photos/") and x.endswith(".webp")])==132
    assert "lib/widgets/recipe_photo.dart" in file_list
    assert "assets/data/recipes_ar.json" in file_list
    with zipfile.ZipFile(safe_source,"w",zipfile.ZIP_DEFLATED,compresslevel=6) as z:
        for rel in file_list:
            z.write(ROOT/rel,arcname=rel)
    with zipfile.ZipFile(safe_source) as z:
        assert z.testzip() is None
        assert "lib/widgets/recipe_photo.dart" in z.namelist()
    delivered_apk=OUT/APK_NAME
    delivered_apk.write_bytes(apk.read_bytes())
    report["apk_size_bytes"]=delivered_apk.stat().st_size
    report["apk_sha256"]=sha(delivered_apk.read_bytes())
    report["safe_source_size_bytes"]=safe_source.stat().st_size
    report["safe_source_sha256"]=sha(safe_source.read_bytes())
    report["build_type"]="Flutter debug APK (not a signed Google Play release)"
    report["debug_signing_note"]="Debug key can differ from previously installed builds; an in-place upgrade is not guaranteed"
    report["android_apk_image_asset_count_verified"]=131
    AUDIT.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print("BUILD/ZIP VERIFIED: APK",delivered_apk.stat().st_size,"safe source",safe_source.stat().st_size,"photo assets",131)

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--source-root",type=Path)
    ap.add_argument("--package",action="store_true")
    args=ap.parse_args()
    if args.package:package()
    else:
        assert args.source_root is not None,"Source root required"
        prepare(args.source_root)

if __name__=="__main__":main()
