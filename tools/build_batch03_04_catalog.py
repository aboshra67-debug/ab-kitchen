#!/usr/bin/env python3
"""Create isolated JPG/PDF deliveries for existing AB Kitchen V0.7 batches 03 and 04."""
from __future__ import annotations
from pathlib import Path
from collections import defaultdict
import hashlib, io, json, zipfile

from PIL import Image, ImageOps
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
import arabic_reshaper
from bidi.algorithm import get_display
import fitz

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "deliverables"
OUT.mkdir(exist_ok=True)
RECIPES = json.loads((ROOT / "assets/data/recipes_ar.json").read_text(encoding="utf-8"))
RECIPE_BY_ID = {r["id"]: r for r in RECIPES}
assert len(RECIPE_BY_ID) == len(RECIPES) == 148, "Recipes count or IDs changed"

FONT = next((p for p in [
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "/usr/share/fonts/truetype/noto/NotoSansArabic-Regular.ttf",
] if Path(p).is_file()), None)
assert FONT, "Arabic font not installed"
pdfmetrics.registerFont(TTFont("ArabicAB", FONT))

def rtl(t):
    return get_display(arabic_reshaper.reshape(str(t)))

def ar(c, value, x, y, size=15, color="#3A272B"):
    c.setFont("ArabicAB", size)
    c.setFillColor(colors.HexColor(color))
    c.drawRightString(x, y, rtl(value))

def phash(image):
    g = ImageOps.grayscale(image).resize((9, 8), Image.Resampling.LANCZOS)
    pixels = list(g.getdata())
    return sum((1 << (row * 8 + col)) for row in range(8)
               for col in range(8) if pixels[row * 9 + col] > pixels[row * 9 + col + 1])

all_photos = []
for folder in sorted((ROOT / "assets").glob("photos_batch[0-9][0-9]")):
    for p in sorted(folder.glob("*.jpg")):
        rid = p.stem
        assert rid in RECIPE_BY_ID, f"Unknown recipe id {rid}"
        with Image.open(p) as im:
            im.verify()
        with Image.open(p) as im:
            assert im.format == "JPEG", f"Not a JPEG: {p}"
            assert im.width >= 1000 and im.height >= 700, f"Low resolution: {p}"
            dh = phash(im)
            dims = im.size
        all_photos.append((rid, str(p), hashlib.sha256(p.read_bytes()).hexdigest(), dh, dims))
assert len(all_photos) == 74, f"Expected 74 independently staged images; got {len(all_photos)}"
ids = [x[0] for x in all_photos]
assert len(set(ids)) == len(ids), "Repeated recipe ID in staged photos"
hashes = [x[2] for x in all_photos]
assert len(set(hashes)) == len(hashes), "Identical file bytes for multiple recipes"
near_matches = []
for i, x in enumerate(all_photos):
    for y in all_photos[i+1:]:
        distance = (x[3] ^ y[3]).bit_count()
        if distance <= 8:
            near_matches.append({"a":x[0],"b":y[0],"dhash_hamming":distance})
        assert distance > 3, f"Very similar visual images: {x[0]} / {y[0]} (distance {distance})"

existing = {p.stem for p in (ROOT / "assets/photos").glob("*.webp")}
assert set(ids).isdisjoint(existing), "Staged photos overlap bundled recipe IDs"

report = {
    "project":"AB Kitchen", "version":"V0.7",
    "source":"AI-generated realistic food visuals; not real camera photographs",
    "staged_unique_recipe_images":74, "bundled_recipe_images":len(existing)-int("eg_koshari_hero" in existing),
    "still_missing_recipe_photos":len(set(RECIPE_BY_ID)-existing-set(ids)),
    "identical_sha256_duplicates":0, "suspicious_visual_pairs_review":near_matches,
    "modified_app_files":False
}
(OUT / "AB_Kitchen_V07_AllBatches_Audit.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")

def make_batch(num, expected):
    batch = ROOT / "assets" / f"photos_batch{num:02}"
    paths = sorted(batch.glob("*.jpg"))
    assert len(paths) == expected, f"Batch {num} expected {expected} JPEGs, found {len(paths)}"
    if (batch / "manifest.json").exists():
        d=json.loads((batch/"manifest.json").read_text(encoding="utf-8"))
        manifest_ids = d.get("recipe_ids") or [x["id"] for x in d.get("photos",[])]
        assert set(manifest_ids)=={p.stem for p in paths}, f"Batch {num}: manifest mismatch"
    order = {r["id"]:i for i,r in enumerate(RECIPES)}
    paths.sort(key=lambda p:order[p.stem])
    entries = []
    for p in paths:
        with Image.open(p) as im:
            dims = [im.width, im.height]
        entries.append({
            "recipe_id":p.stem, "name_ar":RECIPE_BY_ID[p.stem]["name"],
            "ingredients_ar":[x["name"] for x in RECIPE_BY_ID[p.stem]["ingredients"]],
            "country":RECIPE_BY_ID[p.stem]["country"],
            "filename":p.name, "dimensions":dims,
            "sha256":hashlib.sha256(p.read_bytes()).hexdigest()
        })
    name=f"AB_Kitchen_V07_Batch{num:02}_{expected}"
    manifest={
        "project":"AB Kitchen", "version":"V0.7", "batch":f"{num:02}",
        "count":expected, "image_type":"AI-generated photorealistic representations",
        "photos":entries, "source_branch":"assets/v07-photos-batches02-05",
        "review":"IDs, file count, dimensions, SHA256 and perceptual similarity checked by CI; semantic dish appearance requires human review."
    }
    mf_path=OUT/f"AB_Kitchen_V07_Batch{num:02}_Manifest.json"
    mf_bytes=(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n").encode()
    mf_path.write_bytes(mf_bytes)
    W,H=A4
    pdf_path=OUT/f"{name}_Recipes.pdf"
    c=canvas.Canvas(str(pdf_path),pagesize=A4,pageCompression=1)
    c.setTitle(f"AB Kitchen V0.7 | Batch {num:02} | {expected} distinct recipe images")
    c.setAuthor("AB Kitchen")
    for idx,(entry,p) in enumerate(zip(entries,paths),1):
        c.setFillColor(colors.HexColor("#FFFBF9")); c.rect(0,0,W,H,fill=1,stroke=0)
        c.setFillColor(colors.HexColor("#F6E7E8"));c.roundRect(30,H-110,W-60,80,15,fill=1,stroke=0)
        c.setFont("Helvetica-Bold",22);c.setFillColor(colors.HexColor("#BC536E"));c.drawString(45,H-64,"AB Kitchen")
        c.setFont("Helvetica",10);c.setFillColor(colors.HexColor("#6D545B"))
        c.drawString(46,H-88,f"V0.7   |   Batch {num:02}   |   {idx:02d} / {expected:02d}")
        ar(c,entry["name_ar"], W-42,H-149,20)
        c.setFont("Helvetica-Bold",11);c.drawString(41,H-181,entry["recipe_id"])
        with Image.open(p) as original:
            img=ImageOps.exif_transpose(original).convert("RGB")
            box=(36,232,W-72,355)
            ratio=min(box[2]/img.width,box[3]/img.height)
            width,height=img.width*ratio,img.height*ratio
            x=box[0]+(box[2]-width)/2;y=box[1]+(box[3]-height)/2
            c.setFillColor(colors.HexColor("#EEE8E5"))
            c.roundRect(box[0]-3,box[1]-3,box[2]+6,box[3]+6,10,fill=1,stroke=0)
            c.drawImage(str(p),x,y,width,height,mask="auto")
        ar(c,"المكونات الأساسية: "+ "، ".join(entry["ingredients_ar"][:5]),W-43,197,11)
        c.setStrokeColor(colors.HexColor("#E4D5D5"));c.line(43,159,W-43,159)
        c.setFont("Helvetica",9);c.setFillColor(colors.HexColor("#666166"))
        c.drawString(43,137,f"Independent JPEG  |  {entry['dimensions'][0]} x {entry['dimensions'][1]}")
        c.drawString(43,115,"AI-generated realistic food image; not a documentary photograph.")
        c.drawString(43,94,f"Filename: {entry['filename']}")
        c.showPage()
    c.save()
    assert pdf_path.stat().st_size < 45_000_000, 'PDF too large for direct GitHub delivery'
    doc=fitz.open(pdf_path)
    assert len(doc)==expected
    assert all(p.get_images() and len(p.get_text().strip())>30 for p in doc)
    doc.close()
    zip_path=OUT/f"{name}_JPG.zip"
    with zipfile.ZipFile(zip_path,"w",compression=zipfile.ZIP_DEFLATED,compresslevel=4) as z:
        for p in paths:z.write(p,arcname="photos/"+p.name)
        z.writestr("manifest.json",mf_bytes)
        z.writestr("README.txt",f"AB Kitchen V0.7 batch {num:02}; {expected} JPEG images; AI-generated realistic illustrations.\nAll images named by recipe ID.\nOriginal app source untouched.\n")
    with zipfile.ZipFile(zip_path) as z:
        assert z.testzip() is None
        assert len([n for n in z.namelist() if n.startswith("photos/")])==expected
    print("PASS",num,expected,str(pdf_path),str(zip_path))

make_batch(3,20)
make_batch(4,14)
print("FINAL_AUDIT",json.dumps(report,ensure_ascii=False))
