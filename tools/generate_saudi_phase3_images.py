#!/usr/bin/env python3
"""Generate 20 original offline dish illustrations. They are illustrations, not photographs."""
import json,random,hashlib
from pathlib import Path
from PIL import Image,ImageDraw,ImageFilter
R=Path(__file__).resolve().parents[1]
recipes=json.loads((R/'assets/data/saudi_phase3_recipes.json').read_text(encoding='utf8'))
out=R/'assets/photos';out.mkdir(parents=True,exist_ok=True)
bread={'sa_futaytah_north','sa_mathaan_bread','sa_oqaili_cake'}
dessert={'sa_khumayah_north','sa_dabyazah','sa_khanfaroush','sa_khabeesa','sa_sago'}
fish={'sa_muhammar_barnyush','sa_matban_fish'}
vegetable={'sa_shadkh_rajlah'}
rice={'sa_mandi_lamb','sa_mahmous_qatif','sa_timman_hail','sa_mansaf_tabuk','sa_mammoosh_east'}
for obj in recipes:
    name=obj['id'];rng=random.Random(int(hashlib.sha256(name.encode()).hexdigest()[:12],16))
    W,H=768,512
    im=Image.new('RGB',(W,H))
    pix=im.load()
    for y in range(H):
        for x in range(W):
            noise=rng.randint(-8,8);v=(x*15//W)+(y*20//H)
            pix[x,y]=tuple(max(0,min(255,c+v+noise)) for c in (75,51,38))
    d=ImageDraw.Draw(im,'RGBA')
    d.ellipse((110,55,660,505),fill=(28,17,12,120))
    d.ellipse((124,55,641,477),fill=(241,232,207,255),outline=(252,248,235,255),width=14)
    d.ellipse((162,92,603,441),fill=(217,199,165,255),outline=(184,170,139,140),width=5)
    if name in rice:mode='rice';base=(208,157,83)
    elif name in bread:mode='bread';base=(178,110,48)
    elif name in dessert:mode='dessert';base=(195,130,61)
    elif name in fish:mode='fish';base=(190,147,87)
    elif name in vegetable:mode='vegetable';base=(69,116,52)
    else:mode='stew';base=(139,94,59)
    d.ellipse((185,111,582,419),fill=base,outline=(234,189,114,255),width=6)
    for _ in range(3900 if mode=='rice' else 1150):
        x=rng.randrange(198,571);y=rng.randrange(125,405)
        if ((x-384)/196)**2+((y-261)/149)**2>1:continue
        z=rng.randrange(2,10) if mode!='rice' else 6
        if mode=='vegetable':col=(rng.randrange(40,100),rng.randrange(105,188),rng.randrange(35,88),rng.randrange(155,245))
        else:col=(max(10,min(255,base[0]+rng.randrange(-34,54))),max(10,min(255,base[1]+rng.randrange(-35,58))),max(10,min(255,base[2]+rng.randrange(-24,70))),rng.randrange(90,210))
        d.ellipse((x,y,x+z,y+(3 if mode=='rice' else z//2)),fill=col)
    for _ in range(17 if mode in ('bread','dessert') else 9):
        x=rng.randrange(220,535);y=rng.randrange(146,363);z=rng.randrange(22,53)
        if ((x-384)/196)**2+((y-261)/149)**2>.8:continue
        if mode in ('bread','dessert'):
            d.ellipse((x-z,y-z//2,x+z,y+z//2),fill=(rng.randrange(165,225),rng.randrange(99,158),rng.randrange(40,87),255),outline=(111,63,35,200),width=3)
        elif mode=='fish':
            d.ellipse((x-z//2,y-z//3,x+z,y+z//3),fill=(215,166,105,255),outline=(112,78,56,255),width=2)
        elif mode!='vegetable':
            d.rounded_rectangle((x-z//2,y-z//3,x+z//2,y+z//3),radius=8,fill=(rng.randrange(102,152),rng.randrange(56,93),rng.randrange(35,69),255),outline=(76,44,28,200),width=2)
    for _ in range(65):
        x=rng.randrange(203,563);y=rng.randrange(123,402)
        if ((x-384)/196)**2+((y-261)/149)**2>.86:continue
        c=(rng.randrange(50,96),rng.randrange(117,177),rng.randrange(31,63),rng.randrange(120,240))
        d.line((x,y,x+rng.randrange(2,11),y+rng.randrange(2,7)),fill=c,width=2)
    im=im.filter(ImageFilter.GaussianBlur(.4))
    im.save(out/(name+'.jpg'),format='JPEG',quality=88,optimize=True,subsampling=0)
print('Generated twenty original illustrations for AB Kitchen V0.7.8')
