# -*- coding: utf-8 -*-
"""Besin veritabanını üretir: küratörlü Türk mutfağı + USDA ham besinler.

**İki kaynak, iki gerekçe.** Türk ev yemeklerinin (etli kuru fasulye,
mercimek çorbası, menemen) hiçbir açık veri tabanında karşılığı yok —
onlar elle derleniyor (`foods_curated.json`), ev ölçüsü porsiyonlarıyla
birlikte, çünkü kullanıcı "1 kase" diye düşünüyor, "250 gram" diye
değil. Ham besinlerde (elma, tavuk göğsü, yulaf) tersi geçerli: USDA SR
Legacy zaten kamu malı ve elle yazmak hem uzun hem daha hatalı olurdu.

**Ne yapmaz:** değer uydurmaz. USDA'da Türkçe ad yoksa `nameTr` boş
kalır ve arayüz İngilizcesini gösterir — markette aranamayacak bir
sözcük türetmek kullanıcıya yardım etmez (katalogun §4.1 kuralıyla
aynı).

Çıktı determinist: aynı girdi aynı dosyayı verir, sıralama id'ye göre.

Kaynak (bir kez indirilir, git'e girmez):
    curl -sSL -o tools/cache/usda_sr_legacy.zip \\
      https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_csv_2018-04.zip

Kullanım:
    python tools/build_foods.py
    python tools/build_foods.py --check
"""

import collections
import csv
import io
import json
import os
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
USDA_ZIP = os.path.join(ROOT, 'tools', 'cache', 'usda_sr_legacy.zip')
USDA_DIR = 'FoodData_Central_sr_legacy_food_csv_2018-04/'
CURATED = os.path.join(ROOT, 'tools', 'foods_curated.json')
SELECTION = os.path.join(ROOT, 'tools', 'foods_usda_selection.txt')
OUTPUT = os.path.join(ROOT, 'app', 'assets', 'foods.json')

# Tohum sürümü. Artırmak mevcut kurulumlarda yeniden tohumlamayı
# tetikler (katalogla aynı mekanizma).
FOODS_VERSION = 1

# USDA besin öğesi id'leri.
NUTRIENT_KCAL = '1008'
NUTRIENT_PROTEIN = '1003'
NUTRIENT_CARB = '1005'
NUTRIENT_FAT = '1004'

# USDA kategorisi → bizim türümüz. Kapsamayan kategoriler (baharat,
# yağ, bebek maması) seçim listesine zaten girmiyor.
USDA_CATEGORY = {
    '1': 'sutUrunu',
    '5': 'etBalik',
    '8': 'kahvaltilik',
    '9': 'meyve',
    '10': 'etBalik',
    '11': 'sebze',
    '12': 'kuruyemis',
    '13': 'etBalik',
    '14': 'icecek',
    '15': 'etBalik',
    '16': 'sebze',
    '17': 'etBalik',
    '18': 'tahil',
    '19': 'atistirmalik',
    '20': 'tahil',
    '23': 'atistirmalik',
}


def load(path, default=None):
    if not os.path.exists(path):
        return default
    with io.open(path, encoding='utf-8') as f:
        return json.load(f)


def read_selection():
    """`id  # not` satırlarını okur, yorumları ayıklar."""
    if not os.path.exists(SELECTION):
        return collections.OrderedDict()

    wanted = collections.OrderedDict()
    with io.open(SELECTION, encoding='utf-8') as f:
        for line in f:
            entry = line.split('#')[0].strip()
            if not entry:
                continue
            # "fdcId  slug  Türkçe ad" — Türkçe ad boş bırakılabilir.
            parts = [p.strip() for p in entry.split('|')]
            fdc_id = parts[0]
            slug = parts[1] if len(parts) > 1 and parts[1] else None
            name_tr = parts[2] if len(parts) > 2 and parts[2] else None
            wanted[fdc_id] = (slug, name_tr)
    return wanted


def usda_rows(zf, name):
    with zf.open(USDA_DIR + name) as f:
        return list(csv.DictReader(io.TextIOWrapper(f, encoding='utf-8-sig')))


def slugify(text):
    out = []
    for ch in text.lower():
        out.append(ch if ch.isalnum() else '_')
    slug = ''.join(out)
    while '__' in slug:
        slug = slug.replace('__', '_')
    return slug.strip('_')[:48]


def build_usda(wanted):
    """Seçim listesindeki fdcId'leri kayıt sözlüklerine çevirir."""
    if not wanted:
        return [], []
    if not os.path.exists(USDA_ZIP):
        return [], ['USDA arsivi yok: %s' % USDA_ZIP]

    zf = zipfile.ZipFile(USDA_ZIP)
    foods = {r['fdc_id']: r for r in usda_rows(zf, 'food.csv')}

    # 36 MB'lik besin öğesi tablosunu satır satır gez; hepsini belleğe
    # almak gereksiz, aradığımız birkaç yüz kayıt.
    values = collections.defaultdict(dict)
    keep = {NUTRIENT_KCAL, NUTRIENT_PROTEIN, NUTRIENT_CARB, NUTRIENT_FAT}
    with zf.open(USDA_DIR + 'food_nutrient.csv') as f:
        for row in csv.DictReader(io.TextIOWrapper(f, encoding='utf-8-sig')):
            if row['fdc_id'] in wanted and row['nutrient_id'] in keep:
                values[row['fdc_id']][row['nutrient_id']] = row['amount']

    records, warnings = [], []
    for fdc_id, (slug, name_tr) in wanted.items():
        food = foods.get(fdc_id)
        if food is None:
            warnings.append('USDA kaydi bulunamadi: %s' % fdc_id)
            continue

        amounts = values.get(fdc_id, {})
        if NUTRIENT_KCAL not in amounts:
            warnings.append('kalori degeri yok: %s' % fdc_id)
            continue

        name_en = food['description']
        record = collections.OrderedDict()
        record['id'] = slug or slugify(name_en)
        record['nameEn'] = name_en
        if name_tr:
            record['nameTr'] = name_tr
        record['category'] = USDA_CATEGORY.get(
            food['food_category_id'], 'diger')
        record['kcal100'] = round(float(amounts[NUTRIENT_KCAL]), 1)
        record['protein100'] = round(
            float(amounts.get(NUTRIENT_PROTEIN, 0) or 0), 1)
        record['carb100'] = round(float(amounts.get(NUTRIENT_CARB, 0) or 0), 1)
        record['fat100'] = round(float(amounts.get(NUTRIENT_FAT, 0) or 0), 1)
        record['source'] = 'usda'
        record['sourceRef'] = 'FDC %s' % fdc_id
        # Porsiyon yok: USDA'nın ev ölçüleri kaynağa göre değişiyor ve
        # çoğu bize uymuyor ("1 cup, chopped"). 100 gram varsayılanı
        # arayüzde zaten işliyor.
        records.append(record)

    return records, warnings


def build():
    curated = load(CURATED, {})
    records = []
    warnings = []

    for entry in curated.get('foods', []):
        record = collections.OrderedDict(entry)
        record.setdefault('source', 'curated')
        if not record.get('portions'):
            warnings.append('kuratorlu kayitta porsiyon yok: %s'
                            % record.get('id'))
        records.append(record)

    usda, usda_warnings = build_usda(read_selection())
    records.extend(usda)
    warnings.extend(usda_warnings)

    seen = set()
    for record in records:
        if record['id'] in seen:
            warnings.append('yinelenen id: %s' % record['id'])
        seen.add(record['id'])

    records.sort(key=lambda r: r['id'])
    return collections.OrderedDict(version=FOODS_VERSION, foods=records), warnings


def main():
    doc, warnings = build()
    for warning in warnings:
        print('UYARI - %s' % warning)

    rendered = json.dumps(doc, ensure_ascii=False, indent=2) + '\n'

    if '--check' in sys.argv:
        with io.open(OUTPUT, encoding='utf-8') as f:
            current = f.read()
        if current != rendered:
            print('FARK: foods.json boru hattinin ciktisiyla eslesmiyor.')
            return 1
        print('foods.json guncel (%d besin)' % len(doc['foods']))
        return 0

    with io.open(OUTPUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write(rendered)
    print('%d besin yazildi -> %s' % (len(doc['foods']), OUTPUT))
    return 0


if __name__ == '__main__':
    sys.exit(main())
