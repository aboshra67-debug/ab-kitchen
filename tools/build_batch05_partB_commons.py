#!/usr/bin/env python3
"""AB Kitchen V0.7: source+license verified real-photo QA delivery, no app edits."""
from pathlib import Path
import requests,io,json,re,html,hashlib,zipfile
from PIL import Image,ImageOps
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from urllib.parse import quote
import arabic_reshaper
from bidi.algorithm import get_display
import fitz

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'deliverables';OUT.mkdir(exist_ok=True)
PHOTO_DIR=ROOT/'assets/photos_batch05_partB_verified'
PHOTO_DIR.mkdir(parents=True,exist_ok=True)
recipes=json.loads((ROOT/'assets/data/recipes_ar.json').read_text(encoding='utf-8'))
assert len(recipes)==148
by_id={r['id']:r for r in recipes}
assert len(by_id)==148
SOURCES=[
 ('eg_baba_ghanoush','Egyptian baba ghanoush.jpg','Stu Spivack','CC BY-SA 2.0','https://creativecommons.org/licenses/by-sa/2.0/'),
 ('eg_pickled_turnip','Lebanese-style Pickled Turnips.jpg','Zak Greant','CC BY 2.0','https://creativecommons.org/licenses/by/2.0/'),
 ('eg_kahk_eid','Kahk.jpg','Michelle Sym','CC BY 2.0','https://creativecommons.org/licenses/by/2.0/'),
 ('eg_mahalabiya','Mahalabia.JPG','Miansari66','CC0','https://creativecommons.org/publicdomain/zero/1.0/'),
]
assert len({x[0] for x in SOURCES})==len(SOURCES)
assert not ({x[0] for x in SOURCES} & {p.stem for p in (ROOT/'assets/photos').glob('*.webp')})
for folder in list((ROOT/'assets').glob('photos_batch[0-9][0-9]')):
 assert not ({x[0] for x in SOURCES} & {p.stem for p in folder.glob('*.jpg')})
session=requests.Session()
session.headers['User-Agent']='ABKitchen/0.7 (verified photo-license-audit; https://github.com/aboshra67-debug/ab-kitchen)'
def plain(x):return html.unescape(re.sub(r'<[^>]*>',' ',str(x))).strip()
entries=[]
for rid,filename,author,expected,licenseurl in SOURCES:
 assert rid in by_id
 response=session.get('https://commons.wikimedia.org/w/api.php',params={
    'action':'query','titles':'File:'+filename,'prop':'imageinfo','iiprop':'url|size|extmetadata',
    'iiurlwidth':1200,'format':'json','formatversion':2},timeout=30)
 response.raise_for_status()
 info=response.json()['query']['pages'][0]
 assert not info.get('missing') and info.get('imageinfo'),f'No source: {filename}'
 item=info['imageinfo'][0]
 pub=plain(item.get('extmetadata',{}).get('LicenseShortName',{}).get('value',''))
 pnorm=re.sub(r'[^A-Z0-9]','',pub.upper())
 if expected=='CC0':
  assert pnorm.startswith('CC0') or 'PUBLICDOMAIN' in pnorm,f'License mismatch {rid}: {pub}'
 else:
  assert re.sub(r'[^A-Z0-9]','',expected.upper()) in pnorm,f'License mismatch {rid}: {pub}'
 url=item.get('thumburl') or item['url']
 assert url.startswith(('https://upload.wikimedia.org/','https://thumb.wikimedia.org/')),f'Not Wikimedia file {url}'
 raw=session.get(url,timeout=50);raw.raise_for_status()
 assert len(raw.content)<8_000_000
 with Image.open(io.BytesIO(raw.content)) as q:
  q.load()
  assert q.width>=350 and q.height>=275
  im=ImageOps.exif_transpose(q).convert('RGB')
  im.thumbnail((1200,1200),Image.Resampling.LANCZOS)
  out=PHOTO_DIR/(rid+'.jpg')
  im.save(out,'JPEG',quality=85,subsampling=0,optimize=True)
  dims=im.size
 entries.append({'recipe_id':rid,'name_ar':by_id[rid]['name'],
     'filename':rid+'.jpg','source_file_page':'https://commons.wikimedia.org/wiki/File:'+quote(filename.replace(' ','_')),
     'original_title':filename,'author':author,'license':expected,'license_url':licenseurl,
     'license_confirmed_online':pub,'derivative_notice':'Resized and re-encoded as JPEG. Attribution and share-alike conditions preserved as applicable.',
     'source_delivery_url':url,'sha256':hashlib.sha256(out.read_bytes()).hexdigest(),
     'width':dims[0],'height':dims[1]})
assert len({r['sha256'] for r in entries})==len(entries)==4
font=next((p for p in ['/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf','/usr/share/fonts/truetype/noto/NotoSansArabic-Regular.ttf'] if Path(p).is_file()),None)
assert font
pdfmetrics.registerFont(TTFont('ABAr',font))
def ar(x):return get_display(arabic_reshaper.reshape(str(x)))
stem='AB_Kitchen_V07_Batch05_PartB_4_Licensed_Real_Photos'
pdf=OUT/(stem+'.pdf')
c=canvas.Canvas(str(pdf),pagesize=A4)
c.setAuthor('AB Kitchen');c.setTitle('AB Kitchen V0.7 - Four licensed original recipe photos')
W,H=A4
for i,r in enumerate(entries,1):
 c.setFillColor(colors.HexColor('#FFFDFC'));c.rect(0,0,W,H,fill=1,stroke=0)
 c.setFillColor(colors.HexColor('#F7E9EC'));c.roundRect(30,H-112,W-60,84,18,fill=1,stroke=0)
 c.setFillColor(colors.HexColor('#B34664'));c.setFont('Helvetica-Bold',24);c.drawString(45,H-67,'AB Kitchen')
 c.setFont('Helvetica',10);c.drawString(46,H-91,f'V0.7  |  Licensed real photographs  |  {i} / 4')
 c.setFont('ABAr',21);c.setFillColor(colors.HexColor('#33242B'));c.drawRightString(W-45,H-149,ar(r['name_ar']))
 c.setFont('Helvetica',10);c.drawString(44,H-173,r['recipe_id'])
 from PIL import Image
 with Image.open(PHOTO_DIR/r['filename']) as im:
  iw,ih=im.size;scale=min((W-82)/iw,367/ih)
  width,height=iw*scale,ih*scale
  c.drawImage(str(PHOTO_DIR/r['filename']),(W-width)/2,212+(367-height)/2,width,height)
 c.setFont('Helvetica-Bold',11);c.setFillColor(colors.HexColor('#534452'))
 c.drawString(42,185,'Photo credit: '+r['author']+' / '+r['license'])
 c.setFont('Helvetica',9);c.drawString(42,163,'Photo: '+r['original_title'])
 c.drawString(42,143,'License: '+r['license_url'])
 c.drawString(42,123,'Modifications: resized and re-encoded JPEG; see attribution manifest for source URL.')
 c.drawString(42,89,'This image is a real photograph from Wikimedia Commons, not AI generated.')
 c.showPage()
c.save()
d=fitz.open(pdf);assert len(d)==4 and all(p.get_images() for p in d);d.close()
manifest={'project':'AB Kitchen','version':'V0.7','batch':'05 Part B',
 'verified_photo_count':4,
 'visual_accuracy_status':'Source captions checked; final in-app crop/display still requires visual user acceptance',
 'photo_type':'Genuine source photographs under individual Creative Commons licences',
 'app_main_or_source_modified':False,
 'photos':entries}
manifestpath=OUT/(stem+'_Attribution.json')
manifestpath.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
zipfile_path=OUT/(stem+'.zip')
with zipfile.ZipFile(zipfile_path,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=5) as z:
 for r in entries:z.write(PHOTO_DIR/r['filename'],'photos/'+r['filename'])
 z.write(manifestpath,'attribution.json')
 z.writestr('README.txt','AB Kitchen V0.7. Four independent genuine Wikimedia Commons photographs with attribution and license information in attribution.json. No app source changes.\n')
with zipfile.ZipFile(zipfile_path) as z:
 assert z.testzip() is None
 assert len([x for x in z.namelist() if x.startswith('photos/')])==4
print('PASS',[(e['recipe_id'],e['license'],e['width'],e['height']) for e in entries])
print('PDF',pdf.stat().st_size,'ZIP',zipfile_path.stat().st_size)
