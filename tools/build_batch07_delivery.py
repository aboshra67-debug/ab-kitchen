#!/usr/bin/env python3
"""Create a QA-checked standalone JPEG/PDF/ZIP package of 2 distinct AB Kitchen recipe photos.
This script does not alter recipe data, Flutter code, or the main branch.
"""
from pathlib import Path
from PIL import Image, ImageOps
import hashlib, json, zipfile
import fitz
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import arabic_reshaper
from bidi.algorithm import get_display

ROOT=Path(__file__).resolve().parents[1]
PHOTOS=ROOT/'assets/photos_batch07'
OUT=ROOT/'deliverables';OUT.mkdir(exist_ok=True)
recipes=json.loads((ROOT/'assets/data/recipes_ar.json').read_text(encoding='utf-8'))
assert len(recipes)==148
index={r['id']:r for r in recipes}
assert len(index)==148
manifest=json.loads((PHOTOS/'manifest.json').read_text(encoding='utf-8'))
ids=[e['recipe_id'] for e in manifest['photos']]
assert len(ids)==2 and len(set(ids))==2
existing={p.stem for p in (ROOT/'assets/photos').glob('*.webp')}
staged={p.stem for folder in (ROOT/'assets').glob('photos_batch[0-9][0-9]')
                  if folder!=PHOTOS for p in folder.glob('*.jpg')}
assert not (set(ids)&(existing|staged)), 'A recipe already has a staged image'
entries=[]
for rid in ids:
    assert rid in index,f'Unknown ID {rid}'
    p=PHOTOS/(rid+'.jpg')
    assert p.is_file(),f'Missing {p}'
    with Image.open(p) as a:a.verify()
    with Image.open(p) as a:
        assert a.format=='JPEG'
        assert a.width>=600 and a.height>=400
        dims=[a.width,a.height]
        sample=ImageOps.grayscale(a).resize((9,8),Image.Resampling.LANCZOS)
        pix=list(sample.getdata())
        dh=sum(1<<(y*8+x) for y in range(8) for x in range(8) if pix[y*9+x]>pix[y*9+x+1])
    entries.append({'recipe_id':rid,'name_ar':index[rid]['name'],
        'filename':p.name,'dimensions':dims,
        'ingredients_ar':[i['name'] for i in index[rid]['ingredients']],
        'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'perceptual_hash':dh})
assert len({e['sha256'] for e in entries})==len(entries)
assert (entries[0]['perceptual_hash']^entries[1]['perceptual_hash']).bit_count()>4, 'Near-duplicate visuals'
font=next((p for p in ['/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf','/usr/share/fonts/truetype/noto/NotoSansArabic-Regular.ttf'] if Path(p).is_file()),None)
assert font
pdfmetrics.registerFont(TTFont('ArabicAB',font))
def ar(text):return get_display(arabic_reshaper.reshape(str(text)))
NAME='AB_Kitchen_V07_Batch07_PartA_02_Recipe_Photos'
path_pdf=OUT/(NAME+'.pdf')
W,H=A4
c=canvas.Canvas(str(path_pdf),pagesize=A4,pageCompression=1)
c.setTitle('AB Kitchen V0.7 Batch 07 Part A - independent photographs')
c.setAuthor('AB Kitchen')
for k,r in enumerate(entries,1):
    c.setFillColor(colors.HexColor('#FFFCFB'));c.rect(0,0,W,H,stroke=0,fill=1)
    c.setFillColor(colors.HexColor('#F7E5E9'));c.roundRect(30,H-115,W-60,85,14,stroke=0,fill=1)
    c.setFillColor(colors.HexColor('#B83E66'));c.setFont('Helvetica-Bold',23)
    c.drawString(46,H-65,'AB Kitchen')
    c.setFont('Helvetica',10);c.drawString(46,H-91,f'V0.7 | Batch 07 | Recipe {k} / 2')
    c.setFillColor(colors.HexColor('#35272C'));c.setFont('ArabicAB',21)
    c.drawRightString(W-44,H-153,ar(r['name_ar']))
    c.setFont('Helvetica-Bold',11);c.drawString(44,H-179,r['recipe_id'])
    src=PHOTOS/r['filename']
    with Image.open(src) as im:
        im=ImageOps.exif_transpose(im)
        scale=min((W-78)/im.width,365/im.height)
        w,h=im.width*scale,im.height*scale
        c.drawImage(str(src),(W-w)/2,229+(365-h)/2,width=w,height=h)
    c.setFont('ArabicAB',11)
    c.drawRightString(W-46,197,ar('المكونات: '+'، '.join(r['ingredients_ar'][:5])))
    c.setStrokeColor(colors.HexColor('#DDD1D2'));c.line(44,168,W-44,168)
    c.setFillColor(colors.HexColor('#554A4D'));c.setFont('Helvetica',10)
    c.drawString(45,143,f'Individual JPEG | {r["dimensions"][0]} x {r["dimensions"][1]}')
    c.drawString(45,123,'AI-generated realistic food image. Not a documentary photograph.')
    c.drawString(45,100,'Source app unchanged. Image staged for final review before integration.')
    c.showPage()
c.save()
with fitz.open(path_pdf) as d:
    assert len(d)==2 and all(p.get_images() and len(p.get_text().strip())>40 for p in d)
assert path_pdf.stat().st_size<30_000_000
status={
'project':'AB Kitchen V0.7','batch':'07 Part A','delivered_photos':2,
'recipe_ids':ids,'individual_images':entries,
'files_checked':['valid JPEG','min dimensions','SHA-256 unique','perceptual distinct','PDF pages with images','ZIP CRC'],
'AI_generated':True,'application_code_changed':False,
'manual_review':'Basic visual check by assistant; final acceptance by project owner pending',
'missing_recipe_images_on_GitHub_after_batch':17,
'separate_previous_fino_image_not_yet_in_GitHub':True
}
mpath=OUT/(NAME+'_Manifest.json')
mpath.write_text(json.dumps(status,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
zpath=OUT/(NAME+'.zip')
with zipfile.ZipFile(zpath,'w',zipfile.ZIP_DEFLATED,compresslevel=5) as z:
    for r in entries:
        z.write(PHOTOS/r['filename'],arcname='photos/'+r['filename'])
    z.write(mpath,arcname='manifest.json')
    z.writestr('README.txt','AB Kitchen v0.7: two independent realistic AI-generated JPEG food images. No code modified.\n')
with zipfile.ZipFile(zpath) as z:
    assert z.testzip() is None
    assert len([n for n in z.namelist() if n.startswith('photos/')])==2
print('PASS 2 recipe photos',path_pdf.stat().st_size,zpath.stat().st_size)
