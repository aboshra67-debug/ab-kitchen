#!/usr/bin/env python3
"""Build isolated three-photo AB Kitchen v0.7 delivery. No app source changes."""
from pathlib import Path
import json,hashlib,io,zipfile
from PIL import Image, ImageOps, ImageDraw
import fitz
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import arabic_reshaper
from bidi.algorithm import get_display

ROOT=Path(__file__).resolve().parents[1]
ASSET=ROOT/'assets'/'photos_batch06'
OUT=ROOT/'deliverables';OUT.mkdir(exist_ok=True)
rec=json.loads((ROOT/'assets/data/recipes_ar.json').read_text('utf-8'))
assert len(rec)==148
lookup={r['id']:r for r in rec}
assert len(lookup)==148
man=json.loads((ASSET/'manifest.json').read_text('utf-8'))
IDS=man['photos']
assert len(IDS)==3 and len(set(IDS))==3
EXIST={p.stem for p in (ROOT/'assets/photos').glob('*.webp')}
STAGED={p.stem for folder in (ROOT/'assets').glob('photos_batch[0-9][0-9]') for p in folder.glob('*.jpg') if folder!=ASSET}
assert not (set(IDS)&(EXIST|STAGED)), 'Existing recipe image would be overwritten'
pids=[ASSET/(i+'.jpg') for i in IDS]
assert all(x.is_file() for x in pids)
def dhash(im):
 z=ImageOps.grayscale(im).resize((9,8))
 p=list(z.getdata())
 return sum(1<<(y*8+x) for y in range(8) for x in range(8) if p[y*9+x]>p[y*9+x+1])
meta=[]
for id,p in zip(IDS,pids):
 assert id in lookup
 with Image.open(p) as im:
  im.verify()
 with Image.open(p) as im:
  assert im.format=='JPEG' and im.width>=600 and im.height>=400
  ph=dhash(im);width,height=im.size
 meta.append({'recipe_id':id,'name_ar':lookup[id]['name'],'ingredients_ar':[x['name'] for x in lookup[id]['ingredients']],'filename':p.name,'width':width,'height':height,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'dhash':ph})
assert len(set(m['sha256'] for m in meta))==3
assert all((meta[i]['dhash']^meta[j]['dhash']).bit_count()>3 for i in range(3) for j in range(i+1,3))
font=next((f for f in ['/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf','/usr/share/fonts/truetype/noto/NotoSansArabic-Regular.ttf'] if Path(f).exists()),None)
assert font
pdfmetrics.registerFont(TTFont('ArabicAB',font))
def rtl(t):return get_display(arabic_reshaper.reshape(str(t)))
name='AB_Kitchen_V07_Batch06_03_Standalone_Photos'
pdf=OUT/(name+'.pdf')
c=canvas.Canvas(str(pdf),pagesize=A4,pageCompression=1)
c.setTitle('AB Kitchen V0.7 Batch 06 - three independent food photos')
c.setAuthor('AB Kitchen')
W,H=A4
for i,(p,info) in enumerate(zip(pids,meta),1):
 c.setFillColor(colors.HexColor('#FFFCFB'));c.rect(0,0,W,H,stroke=0,fill=1)
 c.setFillColor(colors.HexColor('#F8E8E9'));c.roundRect(32,H-112,W-64,82,13,stroke=0,fill=1)
 c.setFont('Helvetica-Bold',22);c.setFillColor(colors.HexColor('#BD5770'));c.drawString(45,H-65,'AB Kitchen')
 c.setFont('Helvetica',10);c.drawString(46,H-91,f'V0.7 | Batch 06 | Independent dish photo {i} / 3')
 c.setFont('ArabicAB',20);c.setFillColor(colors.HexColor('#363037'));c.drawRightString(W-44,H-154,rtl(info['name_ar']))
 c.setFont('Helvetica-Bold',11);c.drawString(44,H-182,info['recipe_id'])
 with Image.open(p) as img:
  im=ImageOps.exif_transpose(img).convert('RGB')
  width,height=im.size;factor=min((W-80)/width,364/height)
  w=width*factor;h=height*factor
  c.drawImage(str(p),(W-w)/2,227+(364-h)/2,width=w,height=h)
 c.setFont('ArabicAB',11);c.drawRightString(W-44,193,rtl('المكونات: '+'، '.join(info['ingredients_ar'][:5])))
 c.setStrokeColor(colors.HexColor('#DDCDD2'));c.line(42,157,W-42,157)
 c.setFont('Helvetica',9);c.setFillColor(colors.HexColor('#62565C'))
 c.drawString(43,131,f'JPEG - {info["width"]} x {info["height"]} | exact recipe ID')
 c.drawString(43,110,'AI-generated food representation; not a documentary photograph.')
 c.drawString(43,85,'Quality check passed; final user approval and in-app crop check pending.')
 c.showPage()
c.save()
with fitz.open(pdf) as d:
 assert len(d)==3
 assert all(p.get_images() and len(p.get_text().strip())>35 for p in d)
assert pdf.stat().st_size<45_000_000
record={'project':'AB Kitchen V0.7','batch':'06','new_photos':3,'photo_type':'AI-generated food imagery',
 'duplicate_recipe_ids':0,'duplicate_exact_sha256':0,'user_review_pending':True,'source_app_untouched':True,
 'still_missing_in_github_recipe_images':19,
 'existing_fino_separate_local_file':True,
 'photos':[{k:v for k,v in m.items() if k!='dhash'} for m in meta]}
path=OUT/(name+'_Manifest.json')
path.write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
archive=OUT/(name+'.zip')
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=4) as z:
 for p in pids:z.write(p,arcname='photos/'+p.name)
 z.write(path,'manifest.json')
 z.writestr('README.txt','AB Kitchen v0.7 batch 06. Three standalone AI-generated food JPEGs, original images, manifest, SHA256 and recipes. Application source unchanged.\\n')
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None and len([f for f in z.namelist() if f.startswith('photos/')])==3
print('PASS 3 images','PDF',pdf.stat().st_size,'ZIP',archive.stat().st_size)
