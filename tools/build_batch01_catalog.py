#!/usr/bin/env python3
"""Build the V0.7 20-photo delivery without modifying app files."""
import hashlib
import io
import json
import shutil
import zipfile
from pathlib import Path

from PIL import Image, ImageOps
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
import arabic_reshaper
from bidi.algorithm import get_display

ROOT = Path(__file__).resolve().parent.parent
BATCH = ROOT / "assets" / "photos_batch01"
OUT = ROOT / "deliverables"
OUT.mkdir(exist_ok=True)
MANIFEST = json.loads((BATCH / "manifest.json").read_text(encoding="utf-8"))
RECIPES = json.loads((ROOT / "assets/data/recipes_ar.json").read_text(encoding="utf-8"))
RECIPE_BY_ID = {recipe["id"]: recipe for recipe in RECIPES}
IDS = MANIFEST["recipe_ids"]

assert len(IDS) == 20 and len(set(IDS)) == 20, "Batch must have 20 distinct recipe ids"
PHOTOS = []
DIGESTS = {}
for rid in IDS:
    assert rid in RECIPE_BY_ID, f"Recipe missing: {rid}"
    assert not (ROOT / "assets/photos" / (rid + ".webp")).exists(), f"Already photographed: {rid}"
    source = BATCH / (rid + ".jpg")
    assert source.is_file(), f"Missing photograph: {source}"
    raw = source.read_bytes()
    digest = hashlib.sha256(raw).hexdigest()
    assert digest not in DIGESTS, f"Duplicate bytes: {rid} and {DIGESTS[digest]}"
    DIGESTS[digest] = rid
    with Image.open(io.BytesIO(raw)) as im:
        im.verify()
    with Image.open(source) as im:
        assert im.format == "JPEG", f"Unexpected type: {rid}"
        assert im.width >= 1000 and im.height >= 700, f"Insufficient resolution: {rid}"
        PHOTOS.append((rid, source, RECIPE_BY_ID[rid], im.size, digest))

font_file = next((p for p in (
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "/usr/share/fonts/truetype/noto/NotoSansArabic-Regular.ttf",
) if Path(p).is_file()), None)
assert font_file, "Arabic font unavailable"
pdfmetrics.registerFont(TTFont("Arabic", font_file))
def ar(value):
    return get_display(arabic_reshaper.reshape(str(value)))
def right(c, text, x, y, size=14, color=colors.HexColor("#15252B")):
    c.setFont("Arabic", size)
    c.setFillColor(color)
    c.drawRightString(x, y, ar(text))

country_names = {"tr":"تركيا","it":"إيطاليا","in":"الهند","ma":"المغرب","lb":"لبنان","eg":"مصر"}
pdf_path = OUT / "AB_Kitchen_V07_Batch01_20_Recipes.pdf"
W, H = A4
c = canvas.Canvas(str(pdf_path), pagesize=A4, pageCompression=1)
c.setTitle("AB Kitchen V0.7 - Batch 01 - 20 Individual Recipe Photos")
c.setAuthor("AB Kitchen")
for idx, (rid, src, recipe, dims, sha) in enumerate(PHOTOS, 1):
    c.setFillColor(colors.HexColor("#FFFCFA"))
    c.rect(0, 0, W, H, stroke=0, fill=1)
    c.setFillColor(colors.HexColor("#F6E7E1"))
    c.roundRect(31, H-111, W-62, 83, 18, stroke=0, fill=1)
    c.setFont("Helvetica-Bold", 22)
    c.setFillColor(colors.HexColor("#CA6279"))
    c.drawString(48, H-67, "AB Kitchen")
    c.setFont("Helvetica", 10)
    c.setFillColor(colors.HexColor("#5B4A4B"))
    c.drawString(49, H-91, "V0.7  |  Photo Collection 01  |  %02d / 20" % idx)
    right(c, recipe["name"], W-45, H-147, 22)
    right(c, country_names.get(recipe["country"],recipe["country"]), W-45, H-178, 12, colors.HexColor("#895A5D"))
    c.setFont("Helvetica-Bold", 11)
    c.setFillColor(colors.HexColor("#8B5773"))
    c.drawString(45, H-176, rid)
    with Image.open(src) as img:
        img = ImageOps.exif_transpose(img).convert("RGB")
        box_x, box_y, box_w, box_h = 39, 205, W-78, 390
        target_w, target_h = img.size
        scale = min(box_w/target_w,box_h/target_h)
        iw, ih = target_w*scale, target_h*scale
        ix, iy = box_x+(box_w-iw)/2,box_y+(box_h-ih)/2
        c.setFillColor(colors.HexColor("#F4EBE5"))
        c.roundRect(box_x-3,box_y-3,box_w+6,box_h+6,14,stroke=0,fill=1)
        c.drawImage(ImageReader(img),ix,iy,width=iw,height=ih,mask="auto")
    right(c, recipe.get("description","")[:110], W-45, 174, 12)
    c.setStrokeColor(colors.HexColor("#E4D2CA"))
    c.line(42, 140, W-42, 140)
    c.setFont("Helvetica", 9)
    c.setFillColor(colors.HexColor("#72656A"))
    c.drawString(42, 115, "Independent JPEG  |  %d x %d" % dims)
    c.drawString(42, 96, "AI-generated photorealistic food visual; not an actual camera photograph.")
    c.drawString(42, 76, "File: %s.jpg" % rid)
    c.showPage()
c.save()

readme = (
    "AB Kitchen V0.7 - First 20 missing recipe visuals\n"
    "This pack contains 20 standalone original AI-generated photorealistic JPEG food images.\n"
    "Each filename is the exact recipe id in assets/data/recipes_ar.json.\n"
    "No application source or existing assets are replaced in this batch.\n"
    "See manifest.json for order, source type and license context.\n"
)
manifest_out = dict(MANIFEST)
manifest_out["photos"] = [
    {"recipe_id":rid,"name_ar":recipe["name"],"country":recipe["country"],
     "description_ar":recipe["description"],"filename":rid+".jpg",
     "dimensions":list(dims),"sha256":digest}
    for rid, src, recipe, dims, digest in PHOTOS
]
manifest_path = OUT / "AB_Kitchen_V07_Batch01_Manifest.json"
manifest_path.write_text(json.dumps(manifest_out,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
zip_path = OUT / "AB_Kitchen_V07_Batch01_20_JPG.zip"
with zipfile.ZipFile(zip_path,"w",compression=zipfile.ZIP_DEFLATED,compresslevel=6) as zf:
    for rid,src,recipe,dims,digest in PHOTOS:
        zf.write(src,arcname="photos/"+rid+".jpg")
    zf.writestr("README.txt",readme)
    zf.write(manifest_path,arcname="manifest.json")
    zf.write(pdf_path,arcname=pdf_path.name)
with zipfile.ZipFile(zip_path) as zf:
    assert zf.testzip() is None
    assert len([x for x in zf.namelist() if x.startswith("photos/") and x.endswith(".jpg")])==20
print("PASS: 20 unique JPGs, names mapped from the original recipe catalog, PDF pages: 20, ZIP verified")
print("PDF",pdf_path, pdf_path.stat().st_size)
print("ZIP",zip_path, zip_path.stat().st_size)
