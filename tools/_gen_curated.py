# -*- coding: utf-8 -*-
"""foods_curated.json ureticisi — kompakt tablodan.

Elle JSON yazmak yerine tablo: 120 kayitta virgul ve tirnak hatasi
kacinilmaz, tablo ise tek satirda okunabiliyor. Uretilen dosya git'e
girer, bu script yalnizca yazim kolayligi icin.

Atwater tutarlilik kontrolu burada da yapiliyor (kcal ~ 4p+4c+9f, %15
tolerans): bir yazim hatasi 250 kalorilik bir yemegi 25 yapabilir ve
kullanicinin gunluk toplamini sessizce bozar.
"""
import collections
import io
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# id | nameTr | nameEn | kategori | kcal | protein | karb | yag |
#   porsiyon TR | porsiyon EN | gram
# Degerler TUBER 2022 / TurKomp referansli, 100 gram uzerinden.
ROWS = [
    # --- Ana yemekler ---
    ("etli_kuru_fasulye", "Etli Kuru Fasulye", "White Beans with Beef", "yemek", 119, 7.0, 13.0, 4.0, "1 kase", "1 bowl", 250),
    ("kuru_fasulye", "Kuru Fasulye", "White Bean Stew", "yemek", 97, 5.5, 14.0, 2.2, "1 kase", "1 bowl", 250),
    ("nohut_yemegi", "Nohut Yemegi", "Chickpea Stew", "yemek", 128, 6.5, 17.0, 4.0, "1 kase", "1 bowl", 250),
    ("etli_nohut", "Etli Nohut", "Chickpea Stew with Beef", "yemek", 148, 8.5, 16.0, 5.8, "1 kase", "1 bowl", 250),
    ("mercimek_yemegi", "Yesil Mercimek Yemegi", "Green Lentil Stew", "yemek", 105, 6.0, 15.0, 2.5, "1 kase", "1 bowl", 250),
    ("izmir_kofte", "Izmir Kofte", "Izmir Meatballs", "yemek", 165, 11.0, 7.0, 10.5, "2 kofte", "2 meatballs", 180),
    ("kofte_izgara", "Izgara Kofte", "Grilled Meatballs", "yemek", 215, 18.0, 3.0, 14.5, "3 kofte", "3 meatballs", 150),
    ("tavuk_sote", "Tavuk Sote", "Chicken Saute", "yemek", 145, 17.0, 5.0, 6.2, "1 porsiyon", "1 serving", 200),
    ("tavuk_izgara", "Izgara Tavuk Gogsu", "Grilled Chicken Breast", "yemek", 165, 31.0, 0.0, 3.6, "1 gogus", "1 breast", 150),
    ("tavuk_but_firin", "Firinda Tavuk But", "Roasted Chicken Thigh", "yemek", 232, 25.0, 0.0, 14.0, "1 but", "1 thigh", 130),
    ("kuru_kofte", "Kuru Kofte", "Pan-Fried Meatballs", "yemek", 245, 17.5, 6.0, 16.5, "4 kofte", "4 meatballs", 140),
    ("etli_biber_dolma", "Etli Biber Dolmasi", "Stuffed Peppers with Meat", "yemek", 128, 5.5, 13.0, 6.0, "2 dolma", "2 peppers", 240),
    ("yaprak_sarma", "Zeytinyagli Yaprak Sarma", "Stuffed Vine Leaves", "yemek", 165, 3.2, 22.0, 7.5, "5 sarma", "5 rolls", 150),
    ("karniyarik", "Karniyarik", "Stuffed Eggplant with Meat", "yemek", 148, 6.5, 9.0, 10.0, "1 adet", "1 piece", 200),
    ("musakka", "Musakka", "Moussaka", "yemek", 152, 7.0, 9.5, 9.5, "1 porsiyon", "1 serving", 250),
    ("guvec", "Etli Sebze Guvec", "Meat and Vegetable Casserole", "yemek", 118, 9.0, 8.0, 5.5, "1 kase", "1 bowl", 280),
    ("kuzu_tas_kebap", "Kuzu Tas Kebap", "Lamb Stew", "yemek", 178, 15.0, 6.0, 10.5, "1 porsiyon", "1 serving", 220),
    ("etli_taze_fasulye", "Etli Taze Fasulye", "Green Beans with Meat", "yemek", 92, 5.0, 7.5, 4.5, "1 kase", "1 bowl", 250),
    ("zeytinyagli_taze_fasulye", "Zeytinyagli Taze Fasulye", "Green Beans in Olive Oil", "yemek", 78, 2.2, 8.0, 4.2, "1 kase", "1 bowl", 220),
    ("imambayildi", "Imambayildi", "Imam Bayildi", "yemek", 122, 1.8, 10.0, 8.5, "1 adet", "1 piece", 200),
    ("kabak_yemegi", "Zeytinyagli Kabak", "Zucchini in Olive Oil", "yemek", 68, 1.8, 7.0, 3.8, "1 kase", "1 bowl", 220),
    ("ispanak_yemegi", "Etli Ispanak", "Spinach with Meat", "yemek", 84, 5.5, 5.5, 4.5, "1 kase", "1 bowl", 250),
    ("pirasa_yemegi", "Zeytinyagli Pirasa", "Leeks in Olive Oil", "yemek", 72, 1.8, 9.5, 3.2, "1 kase", "1 bowl", 220),
    ("turlu", "Sebze Turlu", "Mixed Vegetable Stew", "yemek", 68, 2.0, 8.5, 3.0, "1 kase", "1 bowl", 250),
    ("menemen", "Menemen", "Turkish Scrambled Eggs", "yemek", 118, 7.5, 4.5, 8.0, "1 porsiyon", "1 serving", 200),
    ("sucuklu_yumurta", "Sucuklu Yumurta", "Eggs with Turkish Sausage", "yemek", 232, 14.5, 1.5, 18.5, "1 porsiyon", "1 serving", 150),
    ("omlet", "Omlet", "Omelette", "yemek", 154, 11.0, 1.0, 11.8, "2 yumurta", "2 eggs", 120),
    ("pilav", "Pirinc Pilavi", "Rice Pilaf", "yemek", 145, 3.0, 28.0, 2.5, "1 porsiyon", "1 serving", 180),
    ("bulgur_pilavi", "Bulgur Pilavi", "Bulgur Pilaf", "yemek", 128, 3.5, 24.0, 2.2, "1 porsiyon", "1 serving", 180),
    ("makarna", "Haslanmis Makarna", "Cooked Pasta", "yemek", 158, 5.8, 31.0, 0.9, "1 porsiyon", "1 serving", 200),
    ("makarna_soslu", "Domates Soslu Makarna", "Pasta with Tomato Sauce", "yemek", 148, 4.8, 26.0, 3.0, "1 porsiyon", "1 serving", 250),
    ("manti", "Manti", "Turkish Dumplings", "yemek", 195, 8.5, 26.0, 6.5, "1 porsiyon", "1 serving", 200),
    ("lahmacun", "Lahmacun", "Lahmacun", "yemek", 235, 10.5, 32.0, 7.5, "1 adet", "1 piece", 130),
    ("pide_kiymali", "Kiymali Pide", "Minced Meat Pide", "yemek", 255, 11.5, 31.0, 9.5, "1 dilim", "1 slice", 150),
    ("doner_et", "Et Doner", "Beef Doner", "yemek", 258, 20.0, 2.0, 19.0, "1 porsiyon", "1 serving", 150),
    ("doner_tavuk", "Tavuk Doner", "Chicken Doner", "yemek", 195, 19.5, 2.0, 12.0, "1 porsiyon", "1 serving", 150),
    ("adana_kebap", "Adana Kebap", "Adana Kebab", "yemek", 275, 17.5, 2.0, 22.0, "1 sis", "1 skewer", 180),
    ("balik_izgara", "Izgara Balik", "Grilled Fish", "yemek", 148, 22.0, 0.0, 6.5, "1 porsiyon", "1 serving", 180),
    ("hamsi_tava", "Hamsi Tava", "Fried Anchovies", "yemek", 240, 17.5, 8.0, 15.5, "1 porsiyon", "1 serving", 150),
    ("kiymali_pilav", "Kiymali Pilav", "Rice with Minced Meat", "yemek", 178, 7.0, 26.0, 5.0, "1 porsiyon", "1 serving", 200),
    # --- Corbalar ---
    ("mercimek_corbasi", "Mercimek Corbasi", "Red Lentil Soup", "corba", 62, 3.1, 9.4, 1.4, "1 kase", "1 bowl", 250),
    ("ezogelin_corbasi", "Ezogelin Corbasi", "Ezogelin Soup", "corba", 68, 3.0, 10.5, 1.8, "1 kase", "1 bowl", 250),
    ("yayla_corbasi", "Yayla Corbasi", "Yogurt and Rice Soup", "corba", 58, 2.6, 7.5, 2.0, "1 kase", "1 bowl", 250),
    ("tarhana_corbasi", "Tarhana Corbasi", "Tarhana Soup", "corba", 55, 2.4, 8.5, 1.2, "1 kase", "1 bowl", 250),
    ("domates_corbasi", "Domates Corbasi", "Tomato Soup", "corba", 52, 1.6, 7.5, 1.8, "1 kase", "1 bowl", 250),
    ("sehriye_corbasi", "Tavuklu Sehriye Corbasi", "Chicken Noodle Soup", "corba", 48, 3.2, 6.0, 1.2, "1 kase", "1 bowl", 250),
    ("iskembe_corbasi", "Iskembe Corbasi", "Tripe Soup", "corba", 78, 6.5, 3.5, 4.2, "1 kase", "1 bowl", 250),
    ("brokoli_corbasi", "Brokoli Corbasi", "Broccoli Soup", "corba", 45, 2.2, 5.5, 1.6, "1 kase", "1 bowl", 250),
    # --- Kahvaltiliklar ---
    ("beyaz_peynir", "Beyaz Peynir", "White Cheese", "kahvaltilik", 264, 17.5, 2.0, 20.5, "1 dilim", "1 slice", 30),
    ("kasar_peyniri", "Kasar Peyniri", "Kashkaval Cheese", "kahvaltilik", 345, 25.0, 1.5, 26.5, "1 dilim", "1 slice", 25),
    ("lor_peyniri", "Lor Peyniri", "Curd Cheese", "kahvaltilik", 98, 12.5, 3.0, 4.0, "1 kasik", "1 spoon", 30),
    ("haslanmis_yumurta", "Haslanmis Yumurta", "Boiled Egg", "kahvaltilik", 155, 13.0, 1.1, 10.6, "1 yumurta", "1 egg", 55),
    ("zeytin_siyah", "Siyah Zeytin", "Black Olives", "kahvaltilik", 145, 1.0, 4.0, 14.0, "8 tane", "8 pieces", 30),
    ("zeytin_yesil", "Yesil Zeytin", "Green Olives", "kahvaltilik", 132, 1.0, 3.5, 13.0, "8 tane", "8 pieces", 30),
    ("bal", "Bal", "Honey", "kahvaltilik", 304, 0.3, 82.0, 0.0, "1 tatli kasigi", "1 teaspoon", 10),
    ("recel", "Recel", "Jam", "kahvaltilik", 250, 0.4, 62.0, 0.1, "1 tatli kasigi", "1 teaspoon", 15),
    ("tahin", "Tahin", "Tahini", "kahvaltilik", 595, 17.0, 21.0, 50.0, "1 yemek kasigi", "1 tablespoon", 15),
    ("pekmez", "Uzum Pekmezi", "Grape Molasses", "kahvaltilik", 293, 0.5, 72.0, 0.2, "1 yemek kasigi", "1 tablespoon", 20),
    ("tereyagi", "Tereyagi", "Butter", "kahvaltilik", 717, 0.9, 0.1, 79.0, "1 tatli kasigi", "1 teaspoon", 8),
    ("sucuk", "Sucuk", "Turkish Sausage", "kahvaltilik", 430, 22.0, 2.0, 37.0, "3 dilim", "3 slices", 30),
    ("pastirma", "Pastirma", "Pastirma", "kahvaltilik", 240, 32.0, 1.0, 12.0, "3 dilim", "3 slices", 25),
    ("simit", "Simit", "Simit", "kahvaltilik", 320, 9.5, 55.0, 6.5, "1 adet", "1 piece", 100),
    ("borek_peynirli", "Peynirli Borek", "Cheese Borek", "kahvaltilik", 295, 9.5, 28.0, 16.0, "1 dilim", "1 slice", 120),
    ("pogaca", "Pogaca", "Pogaca", "kahvaltilik", 330, 7.5, 40.0, 15.5, "1 adet", "1 piece", 70),
    # --- Ekmek ve tahil ---
    ("beyaz_ekmek", "Beyaz Ekmek", "White Bread", "tahil", 265, 8.5, 49.0, 3.2, "1 dilim", "1 slice", 30),
    ("tam_bugday_ekmek", "Tam Bugday Ekmegi", "Whole Wheat Bread", "tahil", 247, 10.5, 41.0, 3.5, "1 dilim", "1 slice", 30),
    ("cavdar_ekmegi", "Cavdar Ekmegi", "Rye Bread", "tahil", 258, 8.5, 48.0, 3.3, "1 dilim", "1 slice", 30),
    ("yulaf_ezmesi", "Yulaf Ezmesi", "Rolled Oats", "tahil", 389, 16.9, 66.0, 6.9, "1 su bardagi", "1 cup", 80),
    ("misir_gevregi", "Misir Gevregi", "Corn Flakes", "tahil", 357, 7.5, 84.0, 0.4, "1 kase", "1 bowl", 40),
    # --- Sut urunleri ---
    ("sut_tam_yagli", "Tam Yagli Sut", "Whole Milk", "sutUrunu", 61, 3.2, 4.8, 3.3, "1 su bardagi", "1 cup", 200),
    ("sut_yarim_yagli", "Yarim Yagli Sut", "Semi-Skimmed Milk", "sutUrunu", 47, 3.4, 4.9, 1.6, "1 su bardagi", "1 cup", 200),
    ("yogurt_tam", "Tam Yagli Yogurt", "Full-Fat Yogurt", "sutUrunu", 61, 3.5, 4.7, 3.3, "1 kase", "1 bowl", 200),
    ("yogurt_light", "Light Yogurt", "Low-Fat Yogurt", "sutUrunu", 47, 4.3, 6.0, 0.5, "1 kase", "1 bowl", 200),
    ("suzme_yogurt", "Suzme Yogurt", "Strained Yogurt", "sutUrunu", 97, 9.0, 3.9, 5.0, "1 kase", "1 bowl", 150),
    ("kefir", "Kefir", "Kefir", "sutUrunu", 55, 3.3, 4.5, 2.5, "1 bardak", "1 glass", 250),
    ("labne", "Labne", "Labneh", "sutUrunu", 245, 7.5, 4.0, 22.0, "1 yemek kasigi", "1 tablespoon", 20),
    # --- Icecekler ---
    ("ayran", "Ayran", "Ayran", "icecek", 37, 1.7, 2.9, 2.0, "1 bardak", "1 glass", 250),
    ("cay", "Cay", "Tea, unsweetened", "icecek", 1, 0.0, 0.2, 0.0, "1 bardak", "1 glass", 100),
    ("turk_kahvesi", "Turk Kahvesi", "Turkish Coffee, plain", "icecek", 3, 0.2, 0.5, 0.0, "1 fincan", "1 cup", 70),
    ("filtre_kahve", "Filtre Kahve", "Filter Coffee, black", "icecek", 2, 0.1, 0.3, 0.0, "1 kupa", "1 mug", 240),
    ("sutlu_kahve", "Sutlu Kahve", "Latte", "icecek", 42, 2.2, 3.5, 2.2, "1 kupa", "1 mug", 240),
    ("portakal_suyu", "Portakal Suyu", "Orange Juice", "icecek", 45, 0.7, 10.4, 0.2, "1 bardak", "1 glass", 200),
    ("kola", "Kola", "Cola", "icecek", 42, 0.0, 10.6, 0.0, "1 kutu", "1 can", 330),
    ("kola_zero", "Kola (sekersiz)", "Diet Cola", "icecek", 0, 0.0, 0.0, 0.0, "1 kutu", "1 can", 330),
    ("maden_suyu", "Maden Suyu", "Sparkling Mineral Water", "icecek", 0, 0.0, 0.0, 0.0, "1 sise", "1 bottle", 200),
    ("limonata", "Limonata", "Lemonade", "icecek", 48, 0.1, 12.0, 0.0, "1 bardak", "1 glass", 250),
    ("bira", "Bira", "Beer", "icecek", 43, 0.5, 3.6, 0.0, "1 sise", "1 bottle", 330),
    ("sarap_kirmizi", "Kirmizi Sarap", "Red Wine", "icecek", 85, 0.1, 2.6, 0.0, "1 kadeh", "1 glass", 150),
    ("raki", "Raki", "Raki", "icecek", 231, 0.0, 0.0, 0.0, "1 kadeh", "1 glass", 50),
    # --- Atistirmalik ve tatli ---
    ("baklava", "Baklava", "Baklava", "atistirmalik", 428, 6.5, 50.0, 22.5, "1 dilim", "1 piece", 60),
    ("sutlac", "Sutlac", "Rice Pudding", "atistirmalik", 132, 3.5, 22.0, 3.2, "1 kase", "1 bowl", 150),
    ("kazandibi", "Kazandibi", "Kazandibi", "atistirmalik", 158, 4.0, 26.0, 4.2, "1 dilim", "1 slice", 120),
    ("kunefe", "Kunefe", "Kunefe", "atistirmalik", 385, 8.5, 42.0, 20.0, "1 porsiyon", "1 serving", 150),
    ("lokum", "Lokum", "Turkish Delight", "atistirmalik", 345, 0.2, 86.0, 0.1, "2 adet", "2 pieces", 30),
    ("biskuvi_sade", "Sade Biskuvi", "Plain Biscuit", "atistirmalik", 460, 7.0, 72.0, 16.0, "3 adet", "3 pieces", 25),
    ("cikolata_sutlu", "Sutlu Cikolata", "Milk Chocolate", "atistirmalik", 535, 7.7, 59.0, 30.0, "4 kare", "4 squares", 25),
    ("cikolata_bitter", "Bitter Cikolata", "Dark Chocolate", "atistirmalik", 546, 7.8, 46.0, 35.0, "4 kare", "4 squares", 25),
    ("cips", "Patates Cipsi", "Potato Chips", "atistirmalik", 536, 6.6, 53.0, 34.0, "1 kucuk paket", "1 small bag", 40),
    ("dondurma", "Dondurma", "Ice Cream", "atistirmalik", 207, 3.5, 24.0, 11.0, "2 top", "2 scoops", 100),
    ("kek_sade", "Sade Kek", "Plain Cake", "atistirmalik", 370, 5.5, 52.0, 15.5, "1 dilim", "1 slice", 60),
    ("protein_bar", "Protein Bar", "Protein Bar", "atistirmalik", 370, 30.0, 38.0, 10.0, "1 bar", "1 bar", 60),
    # --- Salata ve meze ---
    ("coban_salata", "Coban Salata", "Shepherd Salad", "sebze", 42, 1.2, 5.0, 2.0, "1 kase", "1 bowl", 200),
    ("mevsim_salata", "Mevsim Salata", "Garden Salad", "sebze", 28, 1.4, 4.0, 0.6, "1 kase", "1 bowl", 200),
    ("cacik", "Cacik", "Cacik", "sebze", 48, 2.5, 4.0, 2.5, "1 kase", "1 bowl", 200),
    ("haydari", "Haydari", "Haydari", "sebze", 165, 7.0, 5.0, 13.0, "1 yemek kasigi", "1 tablespoon", 30),
    ("humus", "Humus", "Hummus", "sebze", 177, 7.9, 14.3, 10.0, "1 yemek kasigi", "1 tablespoon", 30),
    ("piyaz", "Piyaz", "Piyaz", "sebze", 118, 6.0, 14.0, 4.0, "1 kase", "1 bowl", 200),
    ("patates_salatasi", "Patates Salatasi", "Potato Salad", "sebze", 115, 2.0, 17.0, 4.2, "1 kase", "1 bowl", 200),
    # --- Takviye/protein ---
    ("whey_protein", "Whey Protein Tozu", "Whey Protein Powder", "atistirmalik", 380, 78.0, 8.0, 4.0, "1 olcek", "1 scoop", 30),
]


# Atwater denkleminin disinda kalanlar: etanol gram basina 7 kcal
# veriyor ve 4/4/9 uclusunde karsiligi yok. Bunlari kontrolden muaf
# tutmak, kontrolu gevsetmekten iyi — esigi %40'a cekseydik gercek bir
# yazim hatasi da elenmezdi.
ATWATER_EXEMPT = {'bira', 'sarap_kirmizi', 'raki'}


def atwater_ok(food_id, kcal, protein, carb, fat):
    """kcal ~ 4p + 4c + 9f. Bir yazim hatasi burada yakalanir."""
    if food_id in ATWATER_EXEMPT:
        return True
    estimate = 4 * protein + 4 * carb + 9 * fat
    if kcal < 10 or estimate < 10:
        return True
    return abs(estimate - kcal) / kcal <= 0.15


def main():
    bad = [r for r in ROWS if not atwater_ok(r[0], r[4], r[5], r[6], r[7])]
    for row in bad:
        print('ATWATER SAPMASI: %-26s kcal=%s tahmin=%.0f'
              % (row[0], row[4], 4 * row[5] + 4 * row[6] + 9 * row[7]))
    if bad and '--force' not in sys.argv:
        return 1

    ids = [r[0] for r in ROWS]
    dupes = sorted({i for i in ids if ids.count(i) > 1})
    if dupes:
        print('YINELENEN ID: %s' % ', '.join(dupes))
        return 1

    foods = []
    for (fid, tr, en, cat, kcal, protein, carb, fat,
         label_tr, label_en, grams) in ROWS:
        foods.append(collections.OrderedDict([
            ('id', fid),
            ('nameEn', en),
            ('nameTr', tr),
            ('category', cat),
            ('kcal100', float(kcal)),
            ('protein100', protein),
            ('carb100', carb),
            ('fat100', fat),
            ('source', 'curated'),
            ('sourceRef', 'TUBER 2022 / TurKomp'),
            ('portions', [collections.OrderedDict([
                ('id', '%s_std' % fid),
                ('labelTr', label_tr),
                ('labelEn', label_en),
                ('grams', float(grams)),
                ('isDefault', True),
            ])]),
        ]))

    doc = collections.OrderedDict(
        foods=sorted(foods, key=lambda item: item['id']))
    path = os.path.join(ROOT, 'tools', 'foods_curated.json')
    with io.open(path, 'w', encoding='utf-8', newline='\n') as handle:
        json.dump(doc, handle, ensure_ascii=False, indent=2)
        handle.write('\n')
    print('%d kuratorlu besin yazildi' % len(foods))
    return 0


if __name__ == '__main__':
    sys.exit(main())
