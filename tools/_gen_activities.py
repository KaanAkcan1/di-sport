# -*- coding: utf-8 -*-
"""app/assets/activities.json ureticisi.

Serbest aktiviteler ve MET degerleri — 2024 Adult Compendium of
Physical Activities (Herrmann ve ark., J Sport Health Sci).

Katalog hareketlerinden ayri bir liste: "basketbol maci" bir plana
konulacak hareket degil, olmus bitmis bir sey. Kullanicinin sordugu tek
sey ne kadar surdugu.

Kullanim:
    python tools/_gen_activities.py
"""
import collections
import io
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT = os.path.join(ROOT, 'app', 'assets', 'activities.json')

ACTIVITIES_VERSION = 1

# id | nameTr | nameEn | kategori | MET
ROWS = [
    # --- Yuruyus ve kosu ---
    ("walking_slow", "Yavas Yuruyus", "Walking, slow (3 km/h)", "walking", 2.8),
    ("walking_moderate", "Tempolu Yuruyus", "Walking, moderate (5 km/h)", "walking", 3.5),
    ("walking_brisk", "Hizli Yuruyus", "Walking, brisk (6.4 km/h)", "walking", 5.0),
    ("walking_uphill", "Yokus Yukari Yuruyus", "Walking uphill", "walking", 6.3),
    ("hiking", "Doga Yuruyusu", "Hiking, cross country", "walking", 5.3),
    ("stair_climbing", "Merdiven Cikma", "Stair climbing", "walking", 8.8),
    ("running_8", "Kosu (8 km/h)", "Running, 8 km/h", "running", 8.3),
    ("running_10", "Kosu (10 km/h)", "Running, 10 km/h", "running", 9.8),
    ("running_12", "Kosu (12 km/h)", "Running, 12 km/h", "running", 11.8),
    ("jogging_general", "Hafif Kosu", "Jogging, general", "running", 7.0),
    # --- Bisiklet ---
    ("cycling_leisure", "Bisiklet (gezinti)", "Cycling, leisure (16 km/h)", "cycling", 5.8),
    ("cycling_moderate", "Bisiklet (orta tempo)", "Cycling, moderate (19-22 km/h)", "cycling", 8.0),
    ("cycling_vigorous", "Bisiklet (hizli)", "Cycling, vigorous (23-25 km/h)", "cycling", 10.0),
    ("cycling_mountain", "Daglik Bisiklet", "Mountain biking", "cycling", 8.5),
    ("spinning", "Spinning", "Spinning class", "cycling", 8.5),
    # --- Takim ve raket sporlari ---
    ("basketball_game", "Basketbol (mac)", "Basketball, game", "sports", 8.0),
    ("basketball_casual", "Basketbol (serbest)", "Basketball, shooting baskets", "sports", 4.5),
    ("football_casual", "Futbol (serbest)", "Soccer, casual", "sports", 7.0),
    ("football_game", "Futbol (mac)", "Soccer, competitive", "sports", 10.0),
    ("volleyball", "Voleybol", "Volleyball, non-competitive", "sports", 3.0),
    ("tennis_singles", "Tenis (tekler)", "Tennis, singles", "sports", 7.3),
    ("tennis_doubles", "Tenis (ciftler)", "Tennis, doubles", "sports", 6.0),
    ("table_tennis", "Masa Tenisi", "Table tennis", "sports", 4.0),
    ("badminton", "Badminton", "Badminton, social", "sports", 4.5),
    ("handball", "Hentbol", "Handball, general", "sports", 12.0),
    ("padel", "Padel", "Padel", "sports", 6.0),
    # --- Doguş ve su sporlari ---
    ("swimming_leisure", "Yuzme (serbest)", "Swimming, leisurely", "water", 6.0),
    ("swimming_freestyle", "Yuzme (kulvar)", "Swimming, freestyle, moderate", "water", 8.3),
    ("water_aerobics", "Su Aerobigi", "Water aerobics", "water", 5.5),
    ("rowing_moderate", "Kurek", "Rowing, moderate", "water", 7.0),
    ("surfing", "Sorf", "Surfing, body or board", "water", 3.0),
    # --- Dovus ve dans ---
    ("boxing_bag", "Boks (kum torbasi)", "Boxing, punching bag", "combat", 5.5),
    ("boxing_ring", "Boks (ring)", "Boxing, in ring", "combat", 12.8),
    ("martial_arts", "Dovus Sanatlari", "Martial arts, moderate pace", "combat", 10.3),
    ("wrestling", "Gures", "Wrestling", "combat", 6.0),
    ("dancing_general", "Dans", "Dancing, general", "dance", 5.0),
    ("zumba", "Zumba", "Aerobic dance, high impact", "dance", 7.3),
    # --- Salon ve grup dersleri ---
    ("weight_training_light", "Agirlik (hafif)", "Weight training, light effort", "gym", 3.5),
    ("weight_training_vigorous", "Agirlik (yogun)", "Weight training, vigorous effort", "gym", 5.0),
    ("circuit_training", "Circuit Antrenman", "Circuit training", "gym", 7.2),
    ("hiit", "HIIT", "High intensity interval training", "gym", 8.0),
    ("calisthenics_light", "Kalistenik (hafif)", "Calisthenics, light effort", "gym", 3.5),
    ("calisthenics_vigorous", "Kalistenik (yogun)", "Calisthenics, vigorous effort", "gym", 8.0),
    ("pilates", "Pilates", "Pilates, general", "gym", 3.0),
    ("yoga_hatha", "Yoga (hatha)", "Yoga, hatha", "gym", 2.5),
    ("yoga_power", "Yoga (power)", "Yoga, power", "gym", 4.0),
    ("stretching", "Esneme", "Stretching, mild", "gym", 2.3),
    ("rope_jumping", "Ip Atlama", "Rope jumping, moderate", "gym", 11.8),
    ("elliptical", "Eliptik", "Elliptical trainer, moderate", "gym", 5.0),
    ("rowing_machine", "Kurek Makinesi", "Rowing machine, moderate", "gym", 7.0),
    ("stair_machine", "Merdiven Makinesi", "Stair-treadmill ergometer", "gym", 9.0),
    # --- Kis ve acik hava ---
    ("skiing_downhill", "Kayak", "Skiing, downhill, moderate", "outdoor", 5.3),
    ("ice_skating", "Buz Pateni", "Ice skating, general", "outdoor", 7.0),
    ("rollerblading", "Paten", "Rollerblading, moderate", "outdoor", 9.8),
    ("climbing", "Tirmanis", "Rock climbing, ascending", "outdoor", 8.0),
    ("horseback_riding", "Binicilik", "Horseback riding, general", "outdoor", 5.5),
    ("fishing", "Balik Tutma", "Fishing, standing", "outdoor", 3.5),
    ("golf", "Golf", "Golf, walking, carrying clubs", "outdoor", 4.8),
    # --- Ev ve gunluk isler ---
    ("cleaning_light", "Ev Temizligi (hafif)", "Cleaning, light effort", "home", 2.3),
    ("cleaning_heavy", "Ev Temizligi (agir)", "Cleaning, heavy effort", "home", 3.5),
    ("cooking", "Yemek Yapma", "Cooking, standing", "home", 2.0),
    ("gardening", "Bahce Isi", "Gardening, general", "home", 3.8),
    ("mowing_lawn", "Cim Bicme", "Mowing lawn, walking mower", "home", 5.0),
    ("shoveling_snow", "Kar Kureme", "Shoveling snow, by hand", "home", 5.3),
    ("moving_furniture", "Esya Tasima", "Moving furniture, household", "home", 5.8),
    ("carrying_groceries", "Alisveris Tasima", "Carrying groceries upstairs", "home", 7.5),
    ("child_care", "Cocuk Bakimi", "Child care, active", "home", 3.5),
    ("shopping", "Alisveris", "Shopping, walking", "home", 2.3),
    # --- Is ve ulasim ---
    ("desk_work", "Masa Basi Calisma", "Sitting, office work", "work", 1.5),
    ("standing_work", "Ayakta Calisma", "Standing, light work", "work", 2.0),
    ("construction_work", "Insaat Isi", "Construction, general", "work", 5.5),
    ("driving", "Arac Kullanma", "Driving a car", "work", 2.5),
]


def main():
    ids = [row[0] for row in ROWS]
    dupes = sorted({i for i in ids if ids.count(i) > 1})
    if dupes:
        print('YINELENEN ID: %s' % ', '.join(dupes))
        return 1

    out_of_range = [r for r in ROWS if not 1.0 <= r[4] <= 15.0]
    if out_of_range:
        for row in out_of_range:
            print('MET ARALIK DISI: %s = %s' % (row[0], row[4]))
        return 1

    activities = [
        collections.OrderedDict([
            ('id', fid),
            ('nameEn', name_en),
            ('nameTr', name_tr),
            ('category', category),
            ('met', met),
            ('source', 'compendium'),
        ])
        for (fid, name_tr, name_en, category, met) in ROWS
    ]

    doc = collections.OrderedDict(
        version=ACTIVITIES_VERSION,
        activities=sorted(activities, key=lambda a: a['id']),
    )
    with io.open(OUTPUT, 'w', encoding='utf-8', newline='\n') as handle:
        json.dump(doc, handle, ensure_ascii=False, indent=2)
        handle.write('\n')
    print('%d aktivite yazildi -> %s' % (len(activities), OUTPUT))
    return 0


if __name__ == '__main__':
    sys.exit(main())
