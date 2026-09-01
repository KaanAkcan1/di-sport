import 'dart:convert';

import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/nutrition/data/activities_repository.dart';
import 'package:disport/features/nutrition/data/nutrition_repository.dart';
import 'package:disport/features/nutrition/domain/food.dart';
import 'package:disport/features/workout/application/energy_source_adapter.dart';
import 'package:disport/features/workout/data/workout_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kalori akışlarının **canlı** olduğunun nöbetçisi.
///
/// `IndexedStack` beş sekmeyi de kurulu tutuyor: kullanıcı Bugün'de
/// öğün girip Takvim'e geçtiğinde ekran yeniden kurulmuyor. Tek
/// seferlik okuma yapan bir ekran o anda **eski toplamı** gösterirdi.
///
/// **Widget testi bu kusuru yakalayamaz:** orada ekran her testte
/// sıfırdan kuruluyor, yani koşul hiç doğmuyor. Bu yüzden test gerçek
/// veritabanıyla, akış seviyesinde yazıldı — `progress_reactivity_test`
/// ile aynı gerekçe.
void main() {
  late AppDatabase db;
  late NutritionRepository nutrition;
  late ActivitiesRepository activities;
  late WorkoutRepository workout;

  const foods = {
    'version': 1,
    'foods': [
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

  const activitySeed = {
    'version': 1,
    'activities': [
      {
        'id': 'gardening',
        'nameEn': 'Gardening, general',
        'nameTr': 'Bahçe İşi',
        'category': 'home',
        'met': 4.0,
      },
    ],
  };

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    nutrition = NutritionRepository(db);
    activities = ActivitiesRepository(db);
    workout = WorkoutRepository(db);
    await nutrition.seedFromJson(jsonEncode(foods));
    await activities.seedFromJson(jsonEncode(activitySeed));
  });

  tearDown(() => db.close());

  /// Koşul sağlanana kadar yoklar.
  ///
  /// `.first` kullanılmıyor: akış sağlayıcısında ilk değer **mevcut**
  /// durumdur, sonraki değil. "Yeni veri geldi mi" sorusunu ilk değerle
  /// cevaplamak testi her zaman geçirir.
  Future<T> waitUntil<T>(
    Stream<T> stream,
    bool Function(T value) predicate,
  ) async {
    await for (final value in stream.timeout(const Duration(seconds: 5))) {
      if (predicate(value)) return value;
    }
    fail('akış beklenen değere ulaşmadı');
  }

  test('öğün eklenince gün toplamı yeniden yayılır', () async {
    final stream = nutrition.dayKcal('2026-09-01');
    expect(await stream.first, 0);

    final apple = (await nutrition.foodById('apple_raw'))!;
    await nutrition.addEntry(
      food: apple,
      mealKind: MealKind.araOgun,
      isoDate: '2026-09-01',
      quantity: 2,
    );

    expect(await waitUntil(stream, (value) => value > 0), closeTo(104, 1));
  });

  test('kalem silinince toplam geri düşer', () async {
    final apple = (await nutrition.foodById('apple_raw'))!;
    final id = await nutrition.addEntry(
      food: apple,
      mealKind: MealKind.araOgun,
      isoDate: '2026-09-01',
      quantity: 1,
    );

    final stream = nutrition.dayKcal('2026-09-01');
    await nutrition.removeEntry(id);

    expect(await waitUntil(stream, (value) => value == 0), 0);
  });

  test('aktivite kaydı harcama akışını günceller', () async {
    final gardening = (await activities.byId('gardening'))!;
    final stream = activities.dayKcal('2026-09-01');
    expect(await stream.first, 0);

    await activities.logActivity(
      activity: gardening,
      isoDate: '2026-09-01',
      minutes: 60,
      weightKg: 100,
    );

    expect(await waitUntil(stream, (value) => value > 0), closeTo(400, 2));
  });

  test('antrenman bitince harcama akışı güncellenir', () async {
    final source = EnergySourceAdapter(workout, weightKg: 100);
    final stream = source.burnedOn('2026-09-01');
    expect(await stream.first, 0);

    final start = DateTime(2026, 9, 1, 18);
    await workout.startSession('2026-09-01', now: start);
    // Seans açıkken hâlâ sıfır: bitmemiş antrenmanın süresi bilinmiyor.
    expect(await stream.first, 0);

    await workout.endSession(
      '2026-09-01',
      now: start.add(const Duration(hours: 1)),
    );

    expect(await waitUntil(stream, (value) => value > 0), closeTo(500, 2));
  });

  test('aralık haritası da canlı', () async {
    // Takvim 28 günü tek sorguyla okuyor; o sorgu da yeni kayda
    // tepki vermeli.
    final stream = nutrition.kcalByDayBetween('2026-09-01', '2026-09-07');
    expect(await stream.first, isEmpty);

    final apple = (await nutrition.foodById('apple_raw'))!;
    await nutrition.addEntry(
      food: apple,
      mealKind: MealKind.ogle,
      isoDate: '2026-09-03',
      quantity: 1,
    );

    final totals = await waitUntil(stream, (value) => value.isNotEmpty);
    expect(totals['2026-09-03'], closeTo(52, 1));
  });
}
