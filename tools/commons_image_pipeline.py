#!/usr/bin/env python3
"""Conservatively find Commons-licensed photographs for AB Kitchen's missing Egyptian dishes.
The output is a review artifact: NOTHING is automatically committed or shown in the app.
"""
import argparse, concurrent.futures, hashlib, html, io, json, re, time, unicodedata
from pathlib import Path
from urllib.parse import quote
import requests
from PIL import Image, ImageDraw, ImageOps

QUERIES = {
'eg_macaroni_beshamel':'Egyptian macarona bechamel',
'eg_fatta_meat':'Egyptian fattah beef rice',
'eg_moussaka':'Egyptian moussaka eggplant',
'eg_kebab_halla':'Egyptian kebab halla',
'eg_kofta_oven':'Egyptian baked kofta tray',
'eg_kofta_rice':'Egyptian rice kofta',
'eg_dawood_basha':'Dawood basha kofta',
'eg_molokhia_rabbit':'molokhia rabbit Egyptian',
'eg_tarro_chard':'Egyptian qolqas taro',
'eg_spinach_chickpeas':'spinach chickpeas stew',
'eg_peas_carrots':'Egyptian peas carrots stew',
'eg_fasolia_green':'Egyptian green beans stew',
'eg_okra_meat':'bamya okra beef stew',
'eg_loubia_white':'white beans tomato stew',
'eg_lentil_rice':'Egyptian yellow lentil rice',
'eg_kishk_egyptian':'Egyptian kishk',
'eg_chicken_roasted_onion':'Egyptian roast chicken onion',
'eg_chicken_cream_mushroom':'chicken cream mushroom',
'eg_molokhia_plain':'Egyptian molokhia soup',
'eg_eggplant_minced':'Egyptian eggplant minced meat',
'eg_fatta_chicken':'chicken fattah Egyptian',
'eg_taameya':'Egyptian taameya falafel',
'eg_shakshuka_egypt':'shakshuka eggs tomato',
'eg_egg_pastrami':'eggs basturma Egyptian',
'eg_eggs_potatoes':'potato eggs omelette',
'eg_egg_omelet_veg':'Egyptian eggah omelet',
'eg_cheese_tomato':'Egyptian areesh cheese tomatoes',
'eg_old_cheese_salad':'Egyptian mesh cheese tomato',
'eg_fried_eggplant_breakfast':'Egyptian fried eggplant',
'eg_boiled_fava_green':'green fava beans garlic',
'eg_feteer_sugar':'feteer meshaltet sugar',
'eg_hawawshi':'Egyptian hawawshi',
'eg_liver_alexandria':'Alexandrian liver Egyptian',
'eg_sogo2_alexandria':'Alexandrian sausage Egyptian',
'eg_mombar':'Egyptian mombar stuffed intestines',
'eg_pigeon_freekeh':'Egyptian pigeon stuffed freekeh',
'eg_pigeon_rice':'Egyptian stuffed pigeon rice',
'eg_kaware3':'Egyptian kawarea trotters',
'eg_torb':'Egyptian tarb kofta',
'eg_moza_veg':'Egyptian lamb shank onions',
'eg_fesikh_salad':'Egyptian smoked herring salad',
'eg_ro2a2_meat':'Egyptian ruqaq meat pastry',
'eg_roasted_duck':'Egyptian roasted duck',
'eg_wara2_3enab':'Egyptian stuffed grape leaves',
'eg_cabbage_mahshi':'Egyptian mahshi cabbage',
'eg_onion_mahshi':'stuffed onions Egyptian',
'eg_vine_leaves_meat':'stuffed chard leaves',
'eg_stuffed_tomatoes':'Egyptian stuffed tomatoes rice',
'eg_potato_mahshi_meat':'Egyptian stuffed potatoes meat',
'eg_potato_chicken_tray':'Egyptian chicken potato tray',
'eg_potato_meat_tray':'Egyptian beef potato casserole',
'eg_torly_oven':'Egyptian torly vegetable casserole',
'eg_okka_tagine':'Egyptian okra tagine beef',
'eg_oxtail_tagine':'Egyptian oxtail tagine',
'eg_orzo_tagine':'Egyptian orzo beef tagine',
'eg_rice_moammar':'Egyptian rice moammar',
'eg_macaroni_oven_meat':'Egyptian baked macaroni meat',
'eg_glash_meat_tray':'Egyptian goulash meat pastry',
'eg_okra_shrimp_tagine':'okra shrimp tagine',
'eg_lentil_soup':'Egyptian lentil soup',
'eg_orzo_soup':'orzo soup Egyptian',
'eg_vegetable_soup':'Egyptian vegetable soup',
'eg_tomato_soup':'tomato soup bowl',
'eg_chicken_cream_soup':'chicken cream soup',
'eg_meat_broth':'beef broth Egyptian',
'eg_seafood_soup_eg':'Alexandrian seafood soup',
'eg_sayadeya_rice':'Egyptian sayadeya rice',
'eg_fish_singari':'Egyptian singari baked fish',
'eg_tilapia_grilled':'Egyptian grilled tilapia',
'eg_tilapia_fried':'Egyptian fried tilapia',
'eg_bouri_oven':'Egyptian baked mullet fish',
'eg_shrimp_alex':'Alexandrian shrimp Egyptian',
'eg_shrimp_red_sauce':'shrimp tomato sauce',
'eg_calamari_fried':'fried calamari rings',
'eg_calamari_tagine':'Egyptian squid tagine tomato',
'eg_sardines_fried':'fried sardines Egyptian',
'eg_fish_tahini':'baked fish tahini sauce',
'eg_baladi_bread':'Egyptian baladi bread',
'eg_feteer_meshaltet':'Egyptian feteer meshaltet',
'eg_flahy_qors':'Egyptian qurs bread',
'eg_fino_bread':'Egyptian fino bread',
'eg_qurasa_milk':'Egyptian milk bread',
'eg_feteer_cream':'Egyptian feteer honey cream',
'eg_salata_baladi':'Egyptian salata baladi',
'eg_tahini_salad':'Egyptian tahini sauce salad',
'eg_baba_ghanoush':'Egyptian baba ganoush',
'eg_eggplant_pickled':'Egyptian pickled eggplant',
'eg_yogurt_cucumber':'cucumber yogurt salad',
'eg_duqqa_alex':'Alexandrian duqqa garlic',
'eg_pickled_turnip':'pickled turnips',
'eg_tomato_daqa':'Egyptian tomato daqqa',
'eg_kunafa_cream':'Egyptian kunafa cream',
'eg_atayef_nuts':'Egyptian qatayef nuts',
'eg_balh_sham':'Egyptian balah el sham',
'eg_zalabia':'Egyptian zalabia loukoumades',
'eg_kahk_eid':'Egyptian kahk Eid cookies',
'eg_ghorayeba':'Egyptian ghorayeba',
'eg_petit_four':'Egyptian petit four cookies',
'eg_mahalabiya':'Egyptian mahalabia pudding',
'eg_asoura':'Egyptian ashura wheat pudding',
'eg_meshabbak_domyat':'Egyptian meshabbak',
'eg_sawabe_zainab':'Egyptian sawabe zainab',
'eg_shakalama':'Egyptian coconut shakalama',
'eg_semsemiya':'Egyptian sesame brittle semsemiya',
}

STOP = {'egyptian','egypt','stew','with','sauce','salad','baked','fried','grilled','and','cream','soup','tomato','meat','rice','chicken','bread','beef','traditional','dish','food','plate','homemade','meal','dessert','pastry','egyptian-style'}
ALLOWED = ('CC0','CC BY','CC-BY','PUBLIC DOMAIN','PD-SELF','PD-OLD','PD-ART','CC BY-SA','CC-BY-SA')

def clean(s):
    return html.unescape(re.sub('<[^>]+>',' ',str(s or ''))).strip()

def retrieve(rid, query, timeout=20):
    ses = requests.Session(); ses.headers['User-Agent']='ABKitchenRecipes/0.7 (photo-license-research; https://github.com/aboshra67-debug/ab-kitchen)'
    api='https://commons.wikimedia.org/w/api.php'
    terms=[z for z in re.findall(r'[a-z]{3,}',query.lower()) if z not in STOP]
    # Move from overly restrictive long AND queries to distinct dish-name title search.
    anchor=terms[0] if terms else next((z for z in re.findall(r'[a-z]{3,}',query.lower()) if z not in ('egyptian','egypt')), 'food')
    variants=[query, 'intitle:'+anchor, anchor]
    pages=[]; seen=set(); errors=[]
    for variant in variants:
        try:
            params=dict(action='query',generator='search',gsrsearch=variant,gsrnamespace=6,gsrlimit=12,prop='imageinfo',iiprop='url|size|extmetadata',iiurlwidth=640,format='json',formatversion=2)
            resp=ses.get(api,params=params,timeout=timeout)
            if resp.status_code in (429,502,503,504): time.sleep(.8); continue
            resp.raise_for_status()
            for page in resp.json().get('query',{}).get('pages',[]):
                if page.get('title') not in seen:
                    pages.append(page);seen.add(page.get('title'))
            if len(pages)>=8:break
        except Exception as e:
            errors.append(str(e))
    if not pages and errors:return dict(id=rid,query=query,error=' | '.join(errors)[:250],candidates=[])
    results=[]
    for p in pages:
        title=p.get('title','').removeprefix('File:'); info=(p.get('imageinfo') or [{}])[0]
        if not title.lower().endswith(('.jpg','.jpeg','.png','.webp')):continue
        if any(junk in title.lower() for junk in ('catalog','archive','weekly','journal','book','magazine','food chart','encyclop','map of')):continue
        meta=info.get('extmetadata',{})
        lic=clean(meta.get('LicenseShortName',{}).get('value',''))
        usage=clean(meta.get('UsageTerms',{}).get('value',''))
        if not any(z in lic.upper() for z in ALLOWED) or any(z in lic.upper() for z in ('NC','ND')): continue
        if info.get('width',0)<400 or info.get('height',0)<300: continue
        if not info.get('thumburl'):continue
        name=re.sub(r'\.[^.]+$','',title).lower()
        title_terms=set(re.findall(r'[a-z]{3,}',name))
        matched=[t for t in terms if t in name]
        score = len(matched)*4 + (4 if len(terms)>0 and len(matched)==len(terms) else 0) + (2 if anchor in name else 0)
        # accept filenames containing distinctive words, not generic 'Egyptian', 'food' etc
        results.append({
            'title':title,'file_page':'https://commons.wikimedia.org/wiki/File:'+quote(title.replace(' ','_')),
            'license':lic,'license_url':clean(meta.get('LicenseUrl',{}).get('value','')),
            'artist':clean(meta.get('Artist',{}).get('value',''))[:250],
            'credit':clean(meta.get('Credit',{}).get('value',''))[:250],
            'description':clean(meta.get('ImageDescription',{}).get('value',''))[:320],
            'thumbnail':info.get('thumburl'), 'width':info.get('width'), 'height':info.get('height'),
            'matched':matched,'score':score,'usage':usage[:100]})
    results.sort(key=lambda x:-x['score'])
    return dict(id=rid,query=query,candidates=results[:6])

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--limit',type=int,default=0);parser.add_argument('--workers',type=int,default=4);parser.add_argument('--output',default='photo_research');args=parser.parse_args()
    out=Path(args.output);out.mkdir(parents=True,exist_ok=True)
    subset=list(QUERIES.items())[:args.limit or None]
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        results=list(pool.map(lambda x:retrieve(*x),subset))
    (out/'candidates.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
    confirmed=sum(bool(x['candidates'] and x['candidates'][0]['score']>=6) for x in results)
    failures=[x for x in results if x.get('error')]
    stats={'queried':len(results),'high_scored':confirmed,'zero_candidates':sum(not x['candidates'] for x in results),'failed':len(failures)}
    (out/'summary.json').write_text(json.dumps(stats,ensure_ascii=False,indent=2),encoding='utf-8')
    chosen=[x for x in results if x['candidates'] and x['candidates'][0]['score']>=6]
    cards=[]
    ses=requests.Session(); ses.headers['User-Agent']='ABKitchenRecipes/0.7 (photo-license-research; https://github.com/aboshra67-debug/ab-kitchen)'
    for item in chosen:
        try:
            r=ses.get(item['candidates'][0]['thumbnail'],timeout=15)
            r.raise_for_status()
            im=Image.open(io.BytesIO(r.content));im.thumbnail((300,200))
            card=Image.new('RGB',(320,255),'#f7f3ec');card.paste(im,((320-im.width)//2,0))
            pen=ImageDraw.Draw(card)
            pen.text((10,205),item['id'][:38],fill='#1a1919')
            pen.text((10,224),item['candidates'][0]['title'][:39],fill='#454545')
            cards.append(card)
        except Exception as e:print('thumbnail-failure',item['id'],str(e)[:100])
    if cards:
        cols=3;rows=(len(cards)+cols-1)//cols
        sheet=Image.new('RGB',(cols*320,rows*255),'#fff')
        for i,card in enumerate(cards):sheet.paste(card,((i%cols)*320,(i//cols)*255))
        sheet.save(out/'review_contact_sheet.jpg',quality=85)
    print(json.dumps(stats))
    for r in results:
        print(r['id'],':',r['candidates'][0]['title'] if r['candidates'] else 'NONE',r['candidates'][0]['score'] if r['candidates'] else '',r.get('error',''))

if __name__=='__main__':main()