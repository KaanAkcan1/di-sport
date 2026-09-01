import 'dart:convert';

import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/nutrition/data/nutrition_repository.dart';
import 'package:disport/features/nutrition/domain/food.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late NutritionRepository repo;

  Map<String, dynamic> seedDoc({int version = 1, double kcal = 108}) => {
    'version': version,
    'foods': [
      {
        'id': 'etli_kuru_fasulye',
        'nameEn': 'White Beans with Beef',
        'nameTr': 'Etli Kuru Fasulye',
        'category': 'yemek',
        'kcal100': kcal,
        'protein100': 7.2,
        'source': 'curated',
        'portions': [
          {
            'id': 'kase',
            'labelTr': '1 kase',
            'labelEn': '1 bowl',
            'grams': 250.0,
            'isDefault': true,
          },
        ],
      },
      {
        'id': 'apple_raw',
        'nameEn': 'Apples, raw',
        'nameTr': 'Elma',
        'category': 'meyve',
        'kcal100': 52.0,
        'source': 'usda',
      },
    ],
  };

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = NutritionRepository(db);
    await repo.seedFromJson(jsonEncode(seedDoc()));
  });

  tearDown(() => db.close());

  group('tohumlama', () {
    test('besinler ve porsiyonlar yazılır', () async {
      final foods = await repo.watchFoods().first;
      expect(foods, hasLength(2));

      final beans = foods.firstWhere((f) => f.id == 'etli_kuru_fasulye');
      expect(beans.defaultPortion?.grams, 250);
      expect(beans.protein100, 7.2);
    });

    test('aynı sürüm ikinci kez uygulanmaz', () async {
      await repo.seedFromJson(
        jsonEncode(seedDoc(kcal: 999)),
        readVersion: () async => 1,
      );

      final food = await repo.foodById('etli_kuru_fasulye');
      expect(food?.kcal100, 108, reason: 'sürüm artmadan üzerine yazılmamalı');
    });

    test('sürüm artınca değerler tazelenir', () async {
      await repo.seedFromJson(
        jsonEncode(seedDoc(version: 2, kcal: 115)),
        readVersion: () async => 1,
      );

      final food = await repo.foodById('etli_kuru_fasulye');
      expect(food?.kcal100, 115);
    });

    test('kullanıcının sildiği besin geri gelmez', () async {
      // M6 kullanıcı-tanımlı-veri kalıbı: ölçüt satırın varlığı değil
      // silinmişliği. Aksi hâlde kullanıcı aynı şeyi her güncellemede
      // yeniden siler.
      await db.customStatement(
        "UPDATE foods SET deleted_at = 1 WHERE id = 'apple_raw'",
      );

      await repo.seedFromJson(
        jsonEncode(seedDoc(version: 2)),
        readVersion: () async => 1,
      );

      final foods = await repo.watchFoods().first;
      expect(foods.map((f) => f.id), isNot(contains('apple_raw')));
    });
  });

  group('arama', () {
    test('Türkçe adla bulunur', () async {
      final results = await repo.watchFoods(query: 'fasulye').first;
      expect(results.single.id, 'etli_kuru_fasulye');
    });

    test('İngilizce adla da bulunur', () async {
      // Kullanıcı arayüz dili ne olursa olsun aklına geleni yazıyor;
      // tek katlamaya bağlanmak birini cezalandırırdı.
      final results = await repo.watchFoods(query: 'beans').first;
      expect(results.single.id, 'etli_kuru_fasulye');
    });

    test('tür süzmesi çalışır', () async {
      final results = await repo.watchFoods(category: FoodCategory.meyve).first;
      expect(results.single.id, 'apple_raw');
    });
  });

  group('öğün kaydı', () {
    test('porsiyon çarpanı gram ve kaloriye dönüşür', () async {
      final beans = (await repo.foodById('etli_kuru_fasulye'))!;
      await repo.addEntry(
        food: beans,
        mealKind: MealKind.ogle,
        isoDate: '2026-09-01',
        quantity: 3,
        portion: beans.defaultPortion,
      );

      final entries = await repo.watchDay('2026-09-01').first;
      expect(entries.single.grams, 750);
      expect(entries.single.kcal, closeTo(810, 0.5));
      expect(entries.single.foodName, 'Etli Kuru Fasulye');
    });

    test('besin değeri sonradan değişse geçmiş kalem donuk kalır', () async {
      // Planın kritik testi: dün 810 kcal gördüyse bugün de 810
      // görmeli. Aksi hâlde geçmişe güven biter.
      final beans = (await repo.foodById('etli_kuru_fasulye'))!;
      await repo.addEntry(
        food: beans,
        mealKind: MealKind.ogle,
        isoDate: '2026-09-01',
        quantity: 3,
        portion: beans.defaultPortion,
      );

      await repo.seedFromJson(
        jsonEncode(seedDoc(version: 2, kcal: 200)),
        readVersion: () async => 1,
      );

      final entries = await repo.watchDay('2026-09-01').first;
      expect(entries.single.kcal, closeTo(810, 0.5));
      expect((await repo.foodById('etli_kuru_fasulye'))!.kcal100, 200);
    });

    test('gün toplamları kalemleri toplar', () async {
      final beans = (await repo.foodById('etli_kuru_fasulye'))!;
      final apple = (await repo.foodById('apple_raw'))!;

      await repo.addEntry(
        food: beans,
        mealKind: MealKind.ogle,
        isoDate: '2026-09-01',
        quantity: 1,
        portion: beans.defaultPortion,
      );
      await repo.addEntry(
        food: apple,
        mealKind: MealKind.araOgun,
        isoDate: '2026-09-01',
        quantity: 2,
      );

      expect(await repo.dayKcal('2026-09-01').first, closeTo(374, 1));
      // 250 g fasulye x 7.2/100; elmanın proteini sıfır.
      expect(await repo.dayProtein('2026-09-01').first, closeTo(18.0, 0.1));
    });

    test('silinen kalem toplamdan düşer ama satır durur', () async {
      final apple = (await repo.foodById('apple_raw'))!;
      final id = await repo.addEntry(
        food: apple,
        mealKind: MealKind.araOgun,
        isoDate: '2026-09-01',
        quantity: 1,
      );

      await repo.removeEntry(id);

      expect(await repo.dayKcal('2026-09-01').first, 0);
      final rows = await db.select(db.mealEntries).get();
      expect(rows.single.deletedAt, isNotNull);
    });

    test('kalemler öğün sırasına göre gelir', () async {
      final apple = (await repo.foodById('apple_raw'))!;
      await repo.addEntry(
        food: apple,
        mealKind: MealKind.aksam,
        isoDate: '2026-09-01',
        quantity: 1,
      );
      await repo.addEntry(
        food: apple,
        mealKind: MealKind.kahvalti,
        isoDate: '2026-09-01',
        quantity: 1,
      );

      final entries = await repo.watchDay('2026-09-01').first;
      expect(entries.map((e) => e.mealKind), [
        MealKind.kahvalti,
        MealKind.aksam,
      ]);
    });
  });

  group('kcalByDayBetween', () {
    test('aralıktaki günleri gruplar', () async {
      final apple = (await repo.foodById('apple_raw'))!;
      for (final date in ['2026-09-01', '2026-09-01', '2026-09-03']) {
        await repo.addEntry(
          food: apple,
          mealKind: MealKind.araOgun,
          isoDate: date,
          quantity: 1,
        );
      }

      final totals = await repo
          .kcalByDayBetween('2026-09-01', '2026-09-05')
          .first;
      expect(totals['2026-09-01'], closeTo(104, 1));
      expect(totals['2026-09-03'], closeTo(52, 1));
      // Kayıt olmayan gün haritada **yok**: sıfır ile "hiç girilmemiş"
      // ayrı şeyler ve takvim ikisini farklı tonluyor.
      expect(totals.containsKey('2026-09-02'), isFalse);
    });

    test('aralık dışı gün girmez', () async {
      final apple = (await repo.foodById('apple_raw'))!;
      await repo.addEntry(
        food: apple,
        mealKind: MealKind.araOgun,
        isoDate: '2026-08-25',
        quantity: 1,
      );

      final totals = await repo
          .kcalByDayBetween('2026-09-01', '2026-09-05')
          .first;
      expect(totals, isEmpty);
    });
  });

  group('frequent', () {
    test('sık girilen besin önce gelir', () async {
      final beans = (await repo.foodById('etli_kuru_fasulye'))!;
      final apple = (await repo.foodById('apple_raw'))!;
      final now = DateTime(2026, 9, 1);

      for (var i = 0; i < 3; i++) {
        await repo.addEntry(
          food: apple,
          mealKind: MealKind.araOgun,
          isoDate: '2026-08-30',
          quantity: 1,
        );
      }
      await repo.addEntry(
        food: beans,
        mealKind: MealKind.ogle,
        isoDate: '2026-08-30',
        quantity: 1,
      );

      final result = await repo.frequent(now: now).first;
      expect(result.map((f) => f.id), ['apple_raw', 'etli_kuru_fasulye']);
    });

    test('30 günden eski kayıt sayılmaz', () async {
      final apple = (await repo.foodById('apple_raw'))!;
      await repo.addEntry(
        food: apple,
        mealKind: MealKind.araOgun,
        isoDate: '2026-06-01',
        quantity: 1,
      );

      final result = await repo.frequent(now: DateTime(2026, 9, 1)).first;
      expect(result, isEmpty);
    });
  });

  group('copyMeal', () {
    test('en son o öğünün girildiği günü kopyalar', () async {
      // "Dünü kopyala" değil: kullanıcı dün kahvaltı girmemiş olabilir
      // ve boş bir kopya hiçbir işe yaramaz.
      final beans = (await repo.foodById('etli_kuru_fasulye'))!;
      final apple = (await repo.foodById('apple_raw'))!;

      await repo.addEntry(
        food: beans,
        mealKind: MealKind.kahvalti,
        isoDate: '2026-08-28',
        quantity: 1,
        portion: beans.defaultPortion,
      );
      await repo.addEntry(
        food: apple,
        mealKind: MealKind.kahvalti,
        isoDate: '2026-08-28',
        quantity: 2,
      );

      final copied = await repo.copyMeal(
        mealKind: MealKind.kahvalti,
        toIsoDate: '2026-09-01',
      );

      expect(copied, 2);
      final entries = await repo.watchDay('2026-09-01').first;
      expect(entries, hasLength(2));
    });

    test('kopya da donuk — snapshot yeniden hesaplanmaz', () async {
      final beans = (await repo.foodById('etli_kuru_fasulye'))!;
      await repo.addEntry(
        food: beans,
        mealKind: MealKind.kahvalti,
        isoDate: '2026-08-28',
        quantity: 1,
        portion: beans.defaultPortion,
      );

      await repo.seedFromJson(
        jsonEncode(seedDoc(version: 2, kcal: 200)),
        readVersion: () async => 1,
      );
      await repo.copyMeal(
        mealKind: MealKind.kahvalti,
        toIsoDate: '2026-09-01',
      );

      final entries = await repo.watchDay('2026-09-01').first;
      expect(entries.single.kcal, closeTo(270, 1));
    });

    test('o öğünde hiç kayıt yoksa hiçbir şey kopyalanmaz', () async {
      final copied = await repo.copyMeal(
        mealKind: MealKind.gece,
        toIsoDate: '2026-09-01',
      );
      expect(copied, 0);
      expect(await repo.watchDay('2026-09-01').first, isEmpty);
    });

    test('hedef günün kendisi kaynak olarak seçilmez', () async {
      // Aksi hâlde "kopyala" bugünü ikiye katlardı.
      final apple = (await repo.foodById('apple_raw'))!;
      await repo.addEntry(
        food: apple,
        mealKind: MealKind.ogle,
        isoDate: '2026-09-01',
        quantity: 1,
      );

      final copied = await repo.copyMeal(
        mealKind: MealKind.ogle,
        toIsoDate: '2026-09-01',
      );
      expect(copied, 0);
    });
  });
}
