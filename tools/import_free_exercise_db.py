# -*- coding: utf-8 -*-
"""free-exercise-db'den katalog iskeleti üretir.

Kaynak: https://github.com/yuhonas/free-exercise-db (Unlicense, kamu malı)

**Ne yapar:** seçim listesindeki id'leri kaynaktan alır, alanları bizim
şemamıza eşler, `catalog_overrides.json`'daki elle yazılan içeriği
üstüne bindirir ve `app/assets/catalog.json`'ı yazar.

**Ne yapmaz:** içerik uydurmaz. Kaynakta olmayan ve override'da da
bulunmayan alan **boş bırakılır** — uydurma bir "sık yapılan hata",
gerçek bir hata kaydıyla aynı görünür ve kullanıcı ikisini ayırt edemez
(spec §4.3).

Çıktı deterministtir: aynı girdi aynı dosyayı verir, sıralama id'ye
göre. `--check` modu üretilen dosyayı diskteki ile karşılaştırır.

Kullanım:
    python tools/import_free_exercise_db.py
    python tools/import_free_exercise_db.py --check
"""

import collections
import io
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, 'tools', 'cache', 'free-exercise-db.json')
SELECTION = os.path.join(ROOT, 'tools', 'catalog_selection.txt')
OVERRIDES = os.path.join(ROOT, 'tools', 'catalog_overrides.json')
NAMES_TR = os.path.join(ROOT, 'tools', 'catalog_names_tr.json')
OUTPUT = os.path.join(ROOT, 'app', 'assets', 'catalog.json')

# Şu an geçerli tohum sürümü. Artırmak mevcut kurulumlarda yeniden
# tohumlamayı tetikler (`CatalogRepository.seedFromJson`).
CATALOG_VERSION = 4

EQUIPMENT = {
    'body only': 'bodyOnly',
    'barbell': 'barbell',
    'dumbbell': 'dumbbell',
    'kettlebells': 'kettlebell',
    'cable': 'cable',
    'machine': 'machine',
    'bands': 'bands',
    'medicine ball': 'medicineBall',
    'exercise ball': 'exerciseBall',
    'foam roll': 'foamRoll',
    'e-z curl bar': 'ezCurlBar',
    'other': 'other',
    None: 'none',
}

CATEGORY = {
    'strength': 'strength',
    'powerlifting': 'strength',
    'strongman': 'strength',
    'olympic weightlifting': 'strength',
    'plyometrics': 'cardio',
    'cardio': 'cardio',
    'stretching': 'mobility',
}

# Kaynağın üç seviyesi bizim beşliye ortadan eşleniyor; uçlar (1 ve 5)
# yalnız override ile veriliyor çünkü kaynakta karşılıkları yok.
LEVEL = {'beginner': 2, 'intermediate': 3, 'expert': 4}

# Ekipmandan yer türetme. `dumbbell`/`kettlebell`/`bands` ikisinde de
# olabilir — `both`. Salon makineleri eve girmez, vücut ağırlığı
# heryerdedir ama katalogda "ev" sayılıyor: kullanıcı evde antrenman
# yaparken onları görmeli.
LOCATION = {
    'bodyOnly': 'home',
    'none': 'home',
    'other': 'home',
    'bands': 'both',
    'foamRoll': 'both',
    'exerciseBall': 'both',
    'medicineBall': 'both',
    'dumbbell': 'both',
    'kettlebell': 'both',
    'barbell': 'gym',
    'cable': 'gym',
    'machine': 'gym',
    'ezCurlBar': 'gym',
    # Kaynakta olmayan, elle eklenen türler. Barfiks demiri ve paralel
    # bar eve de takılabiliyor; sehpa ve ip zaten taşınabilir.
    'pullUpBar': 'both',
    'dipBars': 'both',
    'bench': 'both',
    'jumpRope': 'both',
    # v3: ev esyasi arti soruluyor; yeri ev.
    'chair': 'home',
    'step': 'home',
}

# Kategori başına MET varsayılanı — 2024 Adult Compendium of Physical
# Activities.
#
# **Neden kayıt başına değil:** kuvvet hareketlerinin MET'i harekete
# göre değil *efora* göre değişiyor; compendium 100 ayrı squat varyantı
# için değer vermiyor, "resistance training, vigorous effort" için tek
# değer veriyor (5.0). Kayıt başına uydurulmuş MET, kaynağı olmayan bir
# kesinlik izlenimi verirdi.
#
# Kardiyoda tersi geçerli: ip atlama (12.3) ile eliptik (5.0) arasında
# iki kattan fazla fark var ve compendium her biri için ayrı değer
# veriyor. Bu yüzden kardiyo kaydı MET'ini **override'dan almak
# zorunda** — eksikse boru hattı uyarıyor.
CATEGORY_MET = {
    'strength': 5.0,   # resistance training, vigorous effort
    'core': 3.8,       # calisthenics, moderate effort
    'mobility': 2.3,   # stretching, hatha yoga
}

# Gövde hareketleri kaynakta ayrı bir kategori değil; kas grubundan
# çıkarılıyor.
CORE_MUSCLES = {'abdominals', 'lower back'}


def slug(name):
    out = []
    for ch in name.lower():
        out.append(ch if ch.isalnum() else '_')
    while '__' in ''.join(out):
        out = list(''.join(out).replace('__', '_'))
    return ''.join(out).strip('_')


def load(path, default=None):
    if not os.path.exists(path):
        return default
    with io.open(path, encoding='utf-8') as f:
        return json.load(f)


def build():
    source = load(SOURCE)
    if source is None:
        raise SystemExit(
            'Kaynak yok: %s\n'
            'İndir: curl -sL -o %s '
            'https://raw.githubusercontent.com/yuhonas/free-exercise-db/'
            'main/dist/exercises.json' % (SOURCE, SOURCE)
        )

    by_id = {}
    for entry in source:
        by_id[slug(entry['name'])] = entry

    with io.open(SELECTION, encoding='utf-8') as f:
        wanted = []
        for line in f:
            # Satır sonu yorumu ("id   # not") ayrıştırılıyor; yoksa
            # yorum id'nin parçası sayılır ve kaynakta bulunamaz.
            entry = line.split('#')[0].strip()
            if entry:
                wanted.append(entry)

    overrides = load(OVERRIDES, {})
    names_tr = load(NAMES_TR, {})
    missing_met = []
    missing = [i for i in wanted if i not in by_id and i not in overrides]
    if missing:
        print('UYARI - kaynakta bulunamadi: %s' % ', '.join(missing))

    exercises = []
    for exercise_id in sorted(set(wanted)):
        entry = by_id.get(exercise_id)
        override = overrides.get(exercise_id, {})

        if entry is None and not override:
            continue

        record = collections.OrderedDict()
        record['id'] = exercise_id
        record['nameEn'] = override.get(
            'nameEn', entry['name'] if entry else exercise_id
        )

        equipment = [EQUIPMENT.get(entry.get('equipment') if entry else None,
                                   'other')]
        record['equipment'] = override.get('equipment', equipment)

        record['category'] = override.get(
            'category',
            'core'
            if entry
            and set(entry.get('primaryMuscles') or []) & CORE_MUSCLES
            and entry.get('category') == 'strength'
            else CATEGORY.get(entry.get('category') if entry else None,
                              'strength'),
        )
        record['location'] = override.get(
            'location', LOCATION.get(record['equipment'][0], 'home')
        )
        record['primaryMuscles'] = override.get(
            'primaryMuscles', entry.get('primaryMuscles', []) if entry else []
        )
        record['secondaryMuscles'] = override.get(
            'secondaryMuscles',
            entry.get('secondaryMuscles', []) if entry else [],
        )
        record['difficulty'] = override.get(
            'difficulty', LEVEL.get(entry.get('level') if entry else None, 3)
        )
        # v3 (T16.4): icerik iki dilli veri. Kaynagin Ingilizce
        # `instructions` alani `executionEn`e gider; Turkce adimlar
        # override'daki `executionTr`den gelir.
        record['executionEn'] = override.get(
            'executionEn', entry.get('instructions', []) if entry else []
        )
        if 'executionTr' in override:
            record['executionTr'] = override['executionTr']
        record['isUserDefined'] = False

        # Elle yazılan alanlar — yoksa yazılmıyor. `null` yazmak ile
        # anahtarı hiç koymamak aynı sonucu veriyor ama dosya okunurken
        # "burada bir şey olmalıydı" izlenimi vermiyor.
        for field in [
            'nameTr',
            'summaryTr', 'summaryEn', 'setupTr', 'setupEn',
            'breathingTr', 'breathingEn', 'tempoTr', 'tempoEn',
            'cuesTr', 'cuesEn', 'commonMistakesTr', 'commonMistakesEn',
            'safetyTr', 'safetyEn',
            'regressions', 'progressions',
            'met', 'metModel', 'imagePath', 'videoQuery',
        ]:
            if field in override:
                record[field] = override[field]

        # Türkçe ad ayrı bir çeviri tablosundan; override dosyası
        # içerik dosyası, çeviri tablosu ise sözlük. İkisini ayırmak
        # çeviriyi gözden geçirilebilir kılıyor.
        if 'nameTr' not in record and exercise_id in names_tr:
            record['nameTr'] = names_tr[exercise_id]

        if 'met' not in record:
            if record['category'] in CATEGORY_MET:
                record['met'] = CATEGORY_MET[record['category']]
            elif record.get('metModel', 'fixed') == 'fixed':
                # `treadmill`/`cycling` modelleri sabit MET kullanmiyor;
                # harcamayi egim ve hizdan hesapliyorlar (ACSM metabolik
                # denklemleri). Onlarda MET aramak yanlis uyari olurdu.
                missing_met.append(exercise_id)

        if 'videoQuery' not in record:
            record['videoQuery'] = '%s form' % record['nameEn'].lower()

        exercises.append(record)

    if missing_met:
        print('UYARI - kardiyo MET degeri yok: %s' % ', '.join(missing_met))

    # Kademeli cita: EN icerik zorunlu degil, eksigi raporlanir.
    missing_en = [
        r['id'] for r in exercises
        if len(r.get('executionEn', [])) < 2 and 'summaryEn' not in r
    ]
    if missing_en:
        print('BILGI - EN icerigi eksik kayit: %d' % len(missing_en))

    return collections.OrderedDict(
        version=CATALOG_VERSION,
        exercises=exercises,
    )


def main():
    doc = build()
    rendered = json.dumps(doc, ensure_ascii=False, indent=2) + '\n'

    if '--check' in sys.argv:
        with io.open(OUTPUT, encoding='utf-8') as f:
            current = f.read()
        if current != rendered:
            print('FARK: catalog.json boru hattinin ciktisiyla eslesmiyor.')
            return 1
        print('catalog.json guncel (%d hareket)' % len(doc['exercises']))
        return 0

    with io.open(OUTPUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write(rendered)
    print('%d hareket yazildi -> %s' % (len(doc['exercises']), OUTPUT))
    return 0


if __name__ == '__main__':
    sys.exit(main())
