#!/usr/bin/env python3
"""Pack AB Kitchen V0.7 batch 05 / part A without changing app source files."""
from pathlib import Path
from collections import Counter
import io,hashlib,json,zipfile
from PIL import Image,ImageOps,ImageDraw
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import arabic_reshaper
from bidi.algorithm import get_display
import fitz
ROOT=Path(__file__).resolve().parents[1]
PART=ROOT/'assets'/'photos_batch05'
OUT=ROOT/'deliverables'
OUT.mkdir(exist_ok=True)
rec=json.loads((ROOT/'assets/data/recipes_ar.json').read_text(encoding='utf-8'))
recipes={r['id']:r for r in rec}
assert len(rec)==148 and len(recipes)==148,'Do not change recipes'
m=json.loads((PART/'manifest.json').read_text(encoding='utf-8'))
ids=m['photo_ids']
assert len(ids)==12 and len(set(ids))==12,'Invalid staging manifest'
assert set(ids).issubset(recipes),'Unknown dish code in batch'
paths=[PART/(rid+'.jpg') for rid in ids]
assert all(p.is_file() for p in paths),'Missing JPEG'
all_staged=[p for folder in (ROOT/'assets').glob('photos_batch[0-9][0-9]') for p in folder.glob('*.jpg')]
assert len({p.stem for p in all_staged})==len(all_staged),'Duplicate staged recipe IDs'
existing={p.stem for p in (ROOT/'assets'/'photos').glob('*.webp')}
assert set(ids).isdisjoint(existing),'One recipe image already bundled in main'
def dhash(im):
 g=ImageOps.grayscale(im).resize((9,8),Image.Resampling.LANCZOS)
 p=list(g.getdata())
 return sum(1<<(row*8+col) for row in range(8) for col in range(8) if p[row*9+col]>p[row*9+col+1])
data=[]
for p in paths:
 with Image.open(p) as a:a.verify()
 with Image.open(p) as im:
  assert im.format=='JPEG' and im.width>=500 and im.height>=350,f'Invalid or undersized JPEG: {p}'
  size=[im.width,im.height]
  ph=dhash(im)
 data.append(dict(recipe_id=p.stem,name_ar=recipes[p.stem]['name'],filename=p.name,
                  dimensions=size,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),dhash=ph,
                  ingredients_ar=[i['name'] for i in recipes[p.stem]['ingredients']]))
assert len({x['sha256'] for x in data})==len(data),'Duplicated image bytes'
near=[]
for i,a in enumerate(data):
 for b in data[i+1:]:
  distance=(a['dhash']^b['dhash']).bit_count()
  if distance<=10:near.append({'a':a['recipe_id'],'b':b['recipe_id'],'distance':distance})
  assert distance>2,f'Visual near-identical image: {a["recipe_id"]} and {b["recipe_id"]}'
font=next((p for p in ['/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
'/usr/share/fonts/truetype/noto/NotoSansArabic-Regular.ttf'] if Path(p).exists()),None)
assert font
pdfmetrics.registerFont(TTFont('ArabicABKitchen',font))
def arab(t):return get_display(arabic_reshaper.reshape(str(t)))
def rt(c,s,x,y,size=14):
 c.setFont('ArabicABKitchen',size);c.setFillColor(colors.HexColor('#392B30'));c.drawRightString(x,y,arab(s))
base='AB_Kitchen_V07_Batch05_PartA_12'
pdf=OUT/(base+'_Recipes.pdf')
c=canvas.Canvas(str(pdf),pagesize=A4,pageCompression=1)
c.setTitle('AB Kitchen V0.7 - Batch05 PartA - 12 recipes')
c.setAuthor('AB Kitchen')
W,H=A4
for i,(p,x) in enumerate(zip(paths,data),1):
 c.setFillColor(colors.HexColor('#FFFDFB'));c.rect(0,0,W,H,stroke=0,fill=1)
 c.setFillColor(colors.HexColor('#F7E7EB'));c.roundRect(30,H-113,W-60,84,16,stroke=0,fill=1)
 c.setFillColor(colors.HexColor('#BE4A68'));c.setFont('Helvetica-Bold',24)
 c.drawString(46,H-66,'AB Kitchen')
 c.setFont('Helvetica',10);c.drawString(46,H-93,f'V0.7   |   Batch 05 - Part A   |   {i:02d} / 12')
 rt(c,x['name_ar'],W-45,H-151,20)
 c.setFont('Helvetica-Bold',10);c.setFillColor(colors.HexColor('#87626E'));c.drawString(44,H-178,x['recipe_id'])
 with Image.open(p) as image:
  im=ImageOps.exif_transpose(image).convert('RGB')
  box=(39,225,W-78,365);factor=min(box[2]/im.width,box[3]/im.height)
  w,h=im.width*factor,im.height*factor
  px=box[0]+(box[2]-w)/2;py=box[1]+(box[3]-h)/2
  c.drawImage(str(p),px,py,width=w,height=h,mask='auto')
 ingredients=x['ingredients_ar']
 rt(c,'المكونات: '+ '، '.join(ingredients[:4]),W-44,190,11)
 if len(ingredients)>4:rt(c,'، '.join(ingredients[4:8]),W-44,165,10)
 c.setStrokeColor(colors.HexColor('#E5D4D9'));c.line(43,143,W-43,143)
 c.setFillColor(colors.HexColor('#665C5E'));c.setFont('Helvetica',9)
 c.drawString(43,122, f'Original individual JPEG: {x["filename"]}  |  {x["dimensions"][0]} x {x["dimensions"][1]}')
 c.drawString(43,99,'AI-generated realistic dish image. Not a camera photograph.')
 c.drawString(43,78,'Staged on isolated GitHub assets branch; application code unchanged.')
 c.showPage()
c.save()
doc=fitz.open(pdf)
assert len(doc)==12
assert all(page.get_images() and len(page.get_text().strip())>35 for page in doc)
doc.close()
assert pdf.stat().st_size<35_000_000,'PDF exceeds GitHub safe limit'
report={"project":"AB Kitchen V0.7","batch":"05 Part A","photos":data,
        "sha256_exact_duplicates":0,"visually_similar_pairs_for_manual_review":near,
        "pdf_pages":12,"original_app_code_modified":False,
        "remaining_missing_after_part_a":22,
        "note":"Visual dish/ingredient correspondence manually checked on model previews; final end-user approval required."}
rpath=OUT/(base+'_Manifest.json')
rpath.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
zpath=OUT/(base+'_JPG.zip')
with zipfile.ZipFile(zpath,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=5) as z:
 for p in paths:z.write(p,arcname='photos/'+p.name)
 z.write(rpath,arcname='manifest.json')
 z.writestr('README.txt','AB Kitchen V0.7 batch 05 part A: 12 independent generated JPEG food images.\nPDF catalog delivered separately. 22 recipe pictures remain. The main app was not modified.\n')
with zipfile.ZipFile(zpath) as z:
 assert z.testzip() is None
 assert len([v for v in z.namelist() if v.startswith('photos/')])==12
sheet=Image.new('RGB',(4*330,3*280),'#FFF6F7')
d=ImageDraw.Draw(sheet)
for i,p in enumerate(paths):
 with Image.open(p) as q:
  im=ImageOps.fit(q.convert('RGB'),(320,225))
  x=(i%4)*330;y=(i//4)*280
  sheet.paste(im,(x,y));d.text((x+4,y+232),f'{i+1:02d} | {p.stem}',fill='#1C171A')
sheet.save(OUT/(base+'_ContactSheet.jpg'),quality=88)
print('PASS',len(paths),'JPEGs',pdf.name,pdf.stat().st_size,zpath.name,zpath.stat().st_size,'manual similarity flags',len(near))
