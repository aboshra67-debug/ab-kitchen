#!/usr/bin/env python3
"""Download approved photo assets via Wikimedia Commons with recorded licenses.

Only curated exact-match food photos that have an independently checked Commons
file page are allowed. Do NOT source imagery from Facebook/Google results.
"""
import io, json, hashlib, time, sys
from pathlib import Path
import requests
from PIL import Image, ImageOps

ROOT=Path(__file__).resolve().parents[1]
MANIFEST=ROOT/'assets/data/approved_photo_sources.json'
OUT=Path('downloaded_approved_photos')
PHOTOS=OUT/'photos'
PHOTOS.mkdir(parents=True,exist_ok=True)
S=requests.Session()
S.headers.update({'User-Agent':'ABKitchen/0.7 (photography license audit; https://github.com/aboshra67-debug/ab-kitchen)'})
records=[]
for item in json.loads(MANIFEST.read_text()):
    report=dict(item)
    file_name=item['filename']
    try:
        resp=S.get('https://commons.wikimedia.org/w/api.php',params={
            'action':'query','titles':'File:'+file_name,'prop':'imageinfo',
            'iiprop':'url|size|extmetadata','iiurlwidth':900,'format':'json','formatversion':2},timeout=25)
        resp.raise_for_status(); page=resp.json()['query']['pages'][0]
        if page.get('missing') or not page.get('imageinfo'):
            raise ValueError('missing Commons image file')
        image=page['imageinfo'][0];meta=image.get('extmetadata',{})
        import re, html
        def plain(s): return html.unescape(re.sub(r'<[^>]+>',' ',str(s))).strip()
        published=plain(meta.get('LicenseShortName',{}).get('value',''))
        expected=item['license']
        normalized=lambda x:re.sub(r'[^A-Z0-9]','',x.upper())
        if expected.upper().startswith('CC0'):
            okay=published.upper().startswith('CC0')
        elif expected=='Public Domain':
            okay=('PUBLIC' in published.upper() and 'DOMAIN' in published.upper())
        else:
            okay=normalized(expected) in normalized(published) or (expected == 'CC0 1.0' and normalized(published) == 'CC0')
        if not okay:raise ValueError(f'license mismatch {published!r} vs {expected!r}')
        url=image.get('thumburl') or image['url']
        if not (url.startswith('https://upload.wikimedia.org/') or url.startswith('https://thumb.wikimedia.org/')):
            raise ValueError(f'thumbnail is not Wikimedia upload host: {url!r}')
        r=S.get(url,timeout=35)
        r.raise_for_status()
        if len(r.content)>8_000_000:raise ValueError('photo is oversized')
        pic=Image.open(io.BytesIO(r.content));pic.load()
        if pic.width<350 or pic.height<275:raise ValueError('photo resolution too small')
        pic=ImageOps.exif_transpose(pic).convert('RGB')
        pic.thumbnail((900,900),Image.Resampling.LANCZOS)
        output=PHOTOS/(item['recipe_id']+'.webp')
        pic.save(output,format='WEBP',quality=81,method=5)
        report.update(status='downloaded',size=output.stat().st_size,sha256=hashlib.sha256(output.read_bytes()).hexdigest(),license_confirmed=published,
          source_file_page='https://commons.wikimedia.org/wiki/File:'+requests.utils.quote(file_name.replace(' ','_'),safe=':/()'),
          source_thumbnail=url,derivative_note='Resized/re-encoded as WebP; attribution and share-alike retained where applicable.')
        print('OK',item['recipe_id'],output.stat().st_size)
    except Exception as exc:
        report.update(status='failed',error=str(exc));print('FAIL',item['recipe_id'],exc)
    records.append(report)
    time.sleep(.2)
(OUT/'photo_sources_attribution.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
count=sum(x['status']=='downloaded' for x in records)
print(f'SUCCESS {count}/{len(records)}')
if count==0:sys.exit(1)