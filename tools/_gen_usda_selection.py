# -*- coding: utf-8 -*-
"""foods_usda_selection.txt ureticisi.

USDA aciklamalarini elle fdcId'ye cevirmek yerine burada aranip
cozuluyor; uretilen secim dosyasi somut id'ler tasiyor, boylece
`build_foods.py` deterministik kaliyor (kaynak surumu degisse bile
ayni kayitlar geliyor, "ilk eslesen" degil).

Turkce adlar elle: USDA'nin makine cevirisi "Cheese, cottage" icin
"Peynir, kulube" gibi bir sey uretir. Karsiligi olmayan kayitta ad bos
birakiliyor ve arayuz Ingilizcesini gosteriyor.
"""
import collections
import csv
import io
import os
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
USDA_ZIP = os.path.join(ROOT, 'tools', 'cache', 'usda_sr_legacy.zip')
USDA_DIR = 'FoodData_Central_sr_legacy_food_csv_2018-04/'
OUTPUT = os.path.join(ROOT, 'tools', 'foods_usda_selection.txt')

# arama onceki | slug | Turkce ad ('' ise bos birakilir)
ROWS = [
    # --- Meyve ---
    ("apples, raw, with skin", "elma", "Elma"),
    ("bananas, raw", "muz", "Muz"),
    ("oranges, raw, all commercial varieties", "portakal", "Portakal"),
    ("tangerines, (mandarin oranges), raw", "mandalina", "Mandalina"),
    ("lemons, raw, without peel", "limon", "Limon"),
    ("grapes, red or green (european type", "uzum", "Uzum"),
    ("strawberries, raw", "cilek", "Cilek"),
    ("watermelon, raw", "karpuz", "Karpuz"),
    ("melons, cantaloupe, raw", "kavun", "Kavun"),
    ("peaches, yellow, raw", "seftali", "Seftali"),
    ("pears, raw", "armut", "Armut"),
    ("apricots, raw", "kayisi", "Kayisi"),
    ("cherries, sweet, raw", "kiraz", "Kiraz"),
    ("plums, raw", "erik", "Erik"),
    ("kiwifruit, green, raw", "kivi", "Kivi"),
    ("pineapple, raw, all varieties", "ananas", "Ananas"),
    ("pomegranates, raw", "nar", "Nar"),
    ("figs, raw", "incir", "Incir"),
    ("dates, medjool", "hurma", "Hurma"),
    ("raisins, dark, seedless", "kuru_uzum", "Kuru Uzum"),
    ("blueberries, raw", "yaban_mersini", "Yaban Mersini"),
    ("avocados, raw, all commercial varieties", "avokado", "Avokado"),
    ("mangos, raw", "mango", "Mango"),
    ("grapefruit, raw, pink and red, all areas", "greyfurt", "Greyfurt"),
    ("persimmons, japanese, raw", "trabzon_hurmasi", "Trabzon Hurmasi"),
    ("apricots, dried, sulfured, uncooked", "kuru_kayisi", "Kuru Kayisi"),
    # --- Sebze ---
    ("tomatoes, red, ripe, raw, year round average", "domates", "Domates"),
    ("cucumber, with peel, raw", "salatalik", "Salatalik"),
    ("lettuce, cos or romaine, raw", "marul", "Marul"),
    ("onions, raw", "sogan", "Sogan"),
    ("peppers, sweet, green, raw", "yesil_biber", "Yesil Biber"),
    ("peppers, sweet, red, raw", "kirmizi_biber", "Kirmizi Biber"),
    ("carrots, raw", "havuc", "Havuc"),
    ("broccoli, raw", "brokoli", "Brokoli"),
    ("cauliflower, raw", "karnabahar", "Karnabahar"),
    ("spinach, raw", "ispanak", "Ispanak"),
    ("squash, summer, zucchini, includes skin, raw", "kabak", "Kabak"),
    ("eggplant, raw", "patlican", "Patlican"),
    ("cabbage, raw", "lahana", "Lahana"),
    ("mushrooms, white, raw", "mantar", "Mantar"),
    ("garlic, raw", "sarimsak", "Sarimsak"),
    ("celery, raw", "kereviz_sapi", "Kereviz Sapi"),
    ("potatoes, boiled, cooked without skin, flesh, without salt",
     "haslanmis_patates", "Haslanmis Patates"),
    ("sweet potato, cooked, boiled, without skin", "tatli_patates",
     "Tatli Patates"),
    ("corn, sweet, yellow, raw", "misir", "Misir"),
    ("beans, snap, green, raw", "taze_fasulye", "Taze Fasulye"),
    ("peas, green, raw", "bezelye", "Bezelye"),
    ("beets, raw", "pancar", "Pancar"),
    ("pumpkin, raw", "bal_kabagi", "Bal Kabagi"),
    ("radishes, raw", "turp", "Turp"),
    ("arugula, raw", "roka", "Roka"),
    ("asparagus, raw", "kuskonmaz", "Kuskonmaz"),
    ("parsley, fresh", "maydanoz", "Maydanoz"),
    ("leeks, (bulb and lower leaf-portion), raw", "pirasa", "Pirasa"),
    ("artichokes, (globe or french), raw", "enginar", "Enginar"),
    ("okra, raw", "bamya", "Bamya"),
    ("turnips, raw", "salgam", "Salgam"),
    ("squash, winter, all varieties, raw", "kis_kabagi", "Kis Kabagi"),
    # --- Kuruyemis ve tohum ---
    ("nuts, almonds, dry roasted, without salt added", "badem", "Badem"),
    ("nuts, walnuts, english", "ceviz", "Ceviz"),
    ("nuts, hazelnuts or filberts", "findik", "Findik"),
    ("nuts, pistachio nuts, raw", "antep_fistigi", "Antep Fistigi"),
    ("peanuts, all types, raw", "yer_fistigi", "Yer Fistigi"),
    ("nuts, cashew nuts, raw", "kaju", "Kaju"),
    ("seeds, sunflower seed kernels, dried", "ay_cekirdegi", "Ay Cekirdegi"),
    ("seeds, pumpkin and squash seed kernels, dried", "kabak_cekirdegi",
     "Kabak Cekirdegi"),
    ("seeds, chia seeds, dried", "chia_tohumu", "Chia Tohumu"),
    ("seeds, flaxseed", "keten_tohumu", "Keten Tohumu"),
    ("seeds, sesame seeds, whole, dried", "susam", "Susam"),
    ("nuts, coconut meat, raw", "hindistan_cevizi", "Hindistan Cevizi"),
    ("peanut butter, smooth style, without salt", "fistik_ezmesi",
     "Fistik Ezmesi"),
    # --- Tahil ---
    ("rice, white, long-grain, regular, cooked, enriched, with salt",
     "pirinc_haslanmis", "Haslanmis Pirinc"),
    ("rice, brown, long-grain, cooked", "esmer_pirinc", "Esmer Pirinc"),
    ("quinoa, cooked", "kinoa", "Kinoa"),
    ("buckwheat groats, roasted, cooked", "karabugday", "Karabugday"),
    ("couscous, cooked", "kuskus", "Kuskus"),
    ("bulgur, cooked", "bulgur_haslanmis", "Haslanmis Bulgur"),
    ("cereals, oats, regular and quick, unenriched, cooked with water",
     "yulaf_lapasi", "Yulaf Lapasi"),
    ("wheat flour, white, all-purpose, enriched, bleached", "bugday_unu",
     "Bugday Unu"),
    ("pasta, cooked, enriched, without added salt", "makarna_haslanmis",
     "Haslanmis Makarna (sade)"),
    ("snacks, popcorn, air-popped", "patlamis_misir", "Patlamis Misir"),
    # --- Bakliyat ---
    ("beans, kidney, red, mature seeds, cooked, boiled, without salt",
     "barbunya_haslanmis", "Haslanmis Barbunya"),
    ("chickpeas (garbanzo beans, bengal gram), mature seeds, cooked, "
     "boiled, without salt", "nohut_haslanmis", "Haslanmis Nohut"),
    ("lentils, mature seeds, cooked, boiled, without salt",
     "mercimek_haslanmis", "Haslanmis Mercimek"),
    ("beans, black, mature seeds, cooked, boiled, without salt",
     "siyah_fasulye", "Siyah Fasulye"),
    ("soybeans, mature cooked, boiled, without salt", "soya_fasulyesi",
     "Soya Fasulyesi"),
    # --- Et, tavuk, balik, yumurta ---
    ("beef, ground, 85% lean meat / 15% fat, raw", "kiyma_85",
     "Dana Kiyma (%15 yagli)"),
    ("beef, ground, 90% lean meat / 10% fat, raw", "kiyma_90",
     "Dana Kiyma (%10 yagli)"),
    ("chicken, broilers or fryers, breast, meat only, cooked, roasted",
     "tavuk_gogsu_pismis", "Pismis Tavuk Gogsu"),
    ("chicken, broilers or fryers, thigh, meat only, cooked, roasted",
     "tavuk_but_pismis", "Pismis Tavuk But"),
    ("turkey, whole, light meat, raw", "hindi_eti", "Hindi Eti"),
    ("fish, salmon, atlantic, farmed, raw", "somon", "Somon"),
    ("fish, tuna, light, canned in water, without salt, drained solids",
     "ton_baligi", "Ton Baligi (konserve)"),
    ("fish, sea bass, mixed species, raw", "levrek", "Levrek"),
    ("fish, anchovy, european, raw", "hamsi", "Hamsi"),
    ("fish, sardine, atlantic, canned in oil, drained solids with bone",
     "sardalya", "Sardalya"),
    ("crustaceans, shrimp, mixed species, raw", "karides", "Karides"),
    ("egg, whole, raw, fresh", "yumurta", "Yumurta"),
    ("egg, white, raw, fresh", "yumurta_beyazi", "Yumurta Beyazi"),
    ("egg, yolk, raw, fresh", "yumurta_sarisi", "Yumurta Sarisi"),
    # --- Sut urunleri ve yaglar ---
    ("cheese, mozzarella, whole milk", "mozzarella", "Mozzarella"),
    ("cheese, cheddar, sharp, sliced", "cheddar", "Cheddar"),
    ("cheese, cottage, lowfat, 2% milkfat", "cottage_peyniri",
     "Cottage Peyniri"),
    ("cheese, feta", "feta_peyniri", "Feta Peyniri"),
    ("cheese, cream", "krem_peynir", "Krem Peynir"),
    ("cheese, parmesan, grated", "parmesan", "Parmesan"),
    ("cream, fluid, heavy whipping", "krema", "Krema"),
    ("oil, olive, salad or cooking", "zeytinyagi", "Zeytinyagi"),
    ("oil, sunflower, linoleic, (approx. 65%)", "aycicek_yagi",
     "Aycicek Yagi"),
    ("margarine, regular, 80% fat, composite, tub, with salt", "margarin",
     "Margarin"),
    ("sugars, granulated", "toz_seker", "Toz Seker"),
]


# Toplu dolgu: elle Turkce ad yazilan listenin ustune, ayni
# kategorilerden sade ham besinler ekleniyor. Bunlarin Turkce adi
# **bos** kaliyor ve arayuz Ingilizcesini gosteriyor — 300 kalemi elle
# cevirmek, her birinde bir uydurma riski demek olurdu ("Cheese,
# cottage" -> "Kulube peyniri"). Kullanici aradigini iki dilde de
# bulabiliyor; ad dogru olmayacaksa Ingilizcesi durmasi daha iyi.
BULK_CATEGORIES = {
    '1': 14,   # sut ve yumurta
    '5': 12,   # tavuk
    '9': 22,   # meyve
    '11': 30,  # sebze
    '12': 10,  # kuruyemis
    '13': 12,  # dana
    '15': 16,  # balik
    '16': 12,  # bakliyat
    '20': 12,  # tahil
    '23': 8,   # atistirmalik
}
BULK_NOISE = (
    'babyfood', 'infant', 'usda commodity', 'school', 'fast food',
    'restaurant', 'formulated', 'imitation', 'reduced sodium',
    'with salt', 'unprepared', 'frozen', 'canned', 'dehydrated',
)


def bulk_fill(foods, already):
    """Kategori basina, en kisa aciklamali sade kayitlar."""
    taken = collections.OrderedDict()
    for category, limit in BULK_CATEGORIES.items():
        pool = []
        for row in foods:
            if row['food_category_id'] != category:
                continue
            if row['fdc_id'] in already:
                continue
            description = row['description'].lower()
            if len(row['description']) > 42:
                continue
            if any(noise in description for noise in BULK_NOISE):
                continue
            pool.append(row)
        # Siralama aciklama uzunlugu sonra id: en sade kayitlar once
        # geliyor ve secim deterministik kaliyor.
        pool.sort(key=lambda r: (len(r['description']), int(r['fdc_id'])))
        for row in pool[:limit]:
            taken[row['fdc_id']] = (
                slugify(row['description']), '', row['description'])
    return taken


def slugify(text):
    out = []
    for ch in text.lower():
        out.append(ch if ch.isalnum() else '_')
    slug = ''.join(out)
    while '__' in slug:
        slug = slug.replace('__', '_')
    return slug.strip('_')[:48]


def main():
    if not os.path.exists(USDA_ZIP):
        print('USDA arsivi yok: %s' % USDA_ZIP)
        return 1

    zf = zipfile.ZipFile(USDA_ZIP)
    with zf.open(USDA_DIR + 'food.csv') as handle:
        foods = list(csv.DictReader(
            io.TextIOWrapper(handle, encoding='utf-8-sig')))

    exact = {}
    for row in foods:
        exact.setdefault(row['description'].lower(), row)

    resolved, missing = collections.OrderedDict(), []
    for prefix, slug, name_tr in ROWS:
        row = exact.get(prefix)
        if row is None:
            # Onek eslesmesi: USDA aciklamalari parantezli ekler
            # tasiyabiliyor ("... (Includes foods for ...)").
            hits = [r for r in foods
                    if r['description'].lower().startswith(prefix)]
            row = hits[0] if hits else None
        if row is None:
            missing.append(prefix)
            continue
        resolved[row['fdc_id']] = (slug, name_tr, row['description'])

    for entry in missing:
        print('UYARI - USDA aciklamasi bulunamadi: %s' % entry)

    resolved.update(bulk_fill(foods, resolved))

    lines = [
        '# USDA SR Legacy secimi — `fdcId | slug | Turkce ad`.',
        '#',
        '# Bu dosya tools/_gen_usda_selection.py ile uretiliyor ama elle de',
        '# duzenlenebilir: id somut oldugu icin kaynak surumu degisse bile',
        '# ayni kayit gelir. Turkce ad bos birakilabilir — karsiligi',
        '# olmayan bir besine ad uydurmak, markette aranamayacak bir',
        '# sozcuk uretmek olurdu.',
        '',
    ]
    for fdc_id, (slug, name_tr, description) in resolved.items():
        lines.append('%s | %s | %s   # %s' % (fdc_id, slug, name_tr,
                                              description))

    with io.open(OUTPUT, 'w', encoding='utf-8', newline='\n') as handle:
        handle.write('\n'.join(lines) + '\n')
    print('%d USDA kaydi secildi -> %s' % (len(resolved), OUTPUT))
    return 1 if missing else 0


if __name__ == '__main__':
    sys.exit(main())
