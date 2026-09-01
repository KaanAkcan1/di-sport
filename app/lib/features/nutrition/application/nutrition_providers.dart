import 'dart:async';

import 'package:disport/app/app.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/nutrition/data/activities_repository.dart';
import 'package:disport/features/nutrition/data/nutrition_repository.dart';
import 'package:disport/features/nutrition/domain/activity.dart';
import 'package:disport/features/nutrition/domain/calorie_budget.dart';
import 'package:disport/features/nutrition/domain/food.dart';
import 'package:disport/features/nutrition/domain/ports.dart';
import 'package:disport/features/plan/application/plan_providers.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/workout/application/energy_source_adapter.dart';
import 'package:disport/features/workout/application/workout_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nutrition_providers.g.dart';

@riverpod
NutritionRepository nutritionRepository(Ref ref) =>
    NutritionRepository(ref.watch(appDatabaseProvider));

@riverpod
ActivitiesRepository activitiesRepository(Ref ref) =>
    ActivitiesRepository(ref.watch(appDatabaseProvider));

/// Kullanıcının son tartısı — kalori hesabının girdisi.
///
/// Tartı yoksa 70 kg varsayılıyor. Sıfır ya da null döndürmek "hiç
/// kalori yakmadın" demek olurdu; ortalama bir yetişkin kilosuyla
/// tahmin üretmek, hiç tahmin üretmemekten iyi ve zaten `≈` ile
/// gösteriliyor.
@riverpod
Stream<double> currentWeightKg(Ref ref) => ref
    .watch(bodyMetricsRepositoryProvider)
    .watchSeries(MetricKinds.weight, limit: 1)
    .map((samples) => samples.isEmpty ? 70.0 : samples.last.value);

/// Portun bağlandığı tek nokta.
///
/// Kilo değişince adaptör yeniden kuruluyor (`ref.watch`): tartı
/// girildiğinde günün tahmini de güncellenmeli.
@riverpod
Future<EnergySource> energySource(Ref ref) async => EnergySourceAdapter(
  ref.watch(workoutRepositoryProvider),
  weightKg: await ref.watch(currentWeightKgProvider.future),
);

/// Seçili günün besin arama sonuçları.
class FoodQuery {
  const FoodQuery({this.text = '', this.category});

  final String text;
  final FoodCategory? category;

  @override
  bool operator ==(Object other) =>
      other is FoodQuery && other.text == text && other.category == category;

  @override
  int get hashCode => Object.hash(text, category);
}

@riverpod
class FoodSearch extends _$FoodSearch {
  @override
  FoodQuery build() => const FoodQuery();

  void setText(String value) =>
      state = FoodQuery(text: value, category: state.category);

  /// Aynı türe tekrar dokunmak seçimi kaldırır.
  void toggleCategory(FoodCategory value) => state = FoodQuery(
    text: state.text,
    category: state.category == value ? null : value,
  );

  void clear() => state = const FoodQuery();
}

@riverpod
Stream<List<Food>> foodResults(Ref ref) {
  final query = ref.watch(foodSearchProvider);
  return ref
      .watch(nutritionRepositoryProvider)
      .watchFoods(query: query.text, category: query.category);
}

/// Son 30 günün sık yedikleri — seçici boş açılmasın diye.
@riverpod
Stream<List<Food>> frequentFoods(Ref ref) =>
    ref.watch(nutritionRepositoryProvider).frequent();

@riverpod
Stream<List<MealEntry>> dayMeals(Ref ref, String isoDate) =>
    ref.watch(nutritionRepositoryProvider).watchDay(isoDate);

@riverpod
Stream<List<ActivityLog>> dayActivities(Ref ref, String isoDate) =>
    ref.watch(activitiesRepositoryProvider).watchDay(isoDate);

@riverpod
Stream<List<Activity>> activityCatalog(Ref ref, String query) =>
    ref.watch(activitiesRepositoryProvider).watchAll(query: query);

/// Bir günün enerji giriş-çıkışı.
///
/// **İki harcama kaynağı burada toplanıyor:** antrenman seansları
/// (`EnergySource` portu üzerinden `workout`'tan) ve serbest
/// aktiviteler (`nutrition`'ın kendi tablosu). Toplamayı porta
/// yaptırmak `workout`'un `nutrition` verisini okuması demek olurdu.
@riverpod
Stream<DayEnergy> dayEnergy(Ref ref, String isoDate) async* {
  final nutrition = ref.watch(nutritionRepositoryProvider);
  final activities = ref.watch(activitiesRepositoryProvider);
  final source = await ref.watch(energySourceProvider.future);

  var eaten = 0.0;
  var trained = 0.0;
  var moved = 0.0;

  final controller = StreamController<DayEnergy>();
  DayEnergy current() =>
      DayEnergy(eaten: eaten, burned: trained + moved);

  final subscriptions = [
    nutrition.dayKcal(isoDate).listen((value) {
      eaten = value;
      controller.add(current());
    }),
    source.burnedOn(isoDate).listen((value) {
      trained = value;
      controller.add(current());
    }),
    activities.dayKcal(isoDate).listen((value) {
      moved = value;
      controller.add(current());
    }),
  ];

  ref.onDispose(() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    controller.close();
  });

  yield* controller.stream;
}

/// Günlük kalori hedefi — etkin plandan.
///
/// Plan yoksa `null`: bütçe yok demek, sıfır bütçe değil (spec §5.4).
@riverpod
Future<int?> dailyKcalGoal(Ref ref) async =>
    (await ref.watch(activePlanProvider.future))?.goals.dailyKcal;

@riverpod
Future<int?> dailyProteinGoal(Ref ref) async =>
    (await ref.watch(activePlanProvider.future))?.goals.proteinG;

/// Bugünün kalan bütçesi — kahraman sayı.
///
/// **Senkron provider, akış değil:** iki asenkron kaynağı (hedef ve
/// günün enerjisi) birleştiriyor ve Riverpod ikisini de kendisi
/// izliyor. Elle akış birleştirmek aynı işi daha kırılgan yapardı.
///
/// Veri henüz gelmediyse `null` dönüyor; ekran bunu "—" olarak
/// gösteriyor. Bütçesi olmayan kullanıcı da `null` alıyor ve ikisi
/// aynı şeyi gösteriyor: gösterilecek bir sayı yok.
@riverpod
double? todayRemainingKcal(Ref ref) {
  final goal = ref.watch(dailyKcalGoalProvider).value;
  final isoDate = ref.watch(todayIsoProvider);
  final energy = ref.watch(dayEnergyProvider(isoDate)).value;

  if (energy == null) return null;
  return remainingBudget(goalKcal: goal, day: energy);
}

/// Kahramanın altındaki göstergenin doluluğu.
@riverpod
double? todayGaugeFraction(Ref ref) {
  final goal = ref.watch(dailyKcalGoalProvider).value;
  final isoDate = ref.watch(todayIsoProvider);
  final energy = ref.watch(dayEnergyProvider(isoDate)).value;

  if (energy == null) return null;
  return gaugeFraction(goalKcal: goal, day: energy);
}

/// Takvim tonlaması: gün → (yenen − yakılan).
@riverpod
Stream<Map<String, double>> netKcalByDay(
  Ref ref,
  String fromIso,
  String toIso,
) async* {
  final nutrition = ref.watch(nutritionRepositoryProvider);
  final activities = ref.watch(activitiesRepositoryProvider);
  final source = await ref.watch(energySourceProvider.future);

  var eaten = <String, double>{};
  var trained = <String, double>{};
  var moved = <String, double>{};

  final controller = StreamController<Map<String, double>>();

  void emit() {
    // Yalnız **yemek girilmiş** günler haritada: sırf antrenman yapılan
    // bir güne eksi kalori yazmak, kullanıcının o gün hiç yemediğini
    // iddia etmek olurdu.
    controller.add({
      for (final entry in eaten.entries)
        entry.key:
            entry.value -
            (trained[entry.key] ?? 0) -
            (moved[entry.key] ?? 0),
    });
  }

  final subscriptions = [
    nutrition.kcalByDayBetween(fromIso, toIso).listen((value) {
      eaten = value;
      emit();
    }),
    source.burnedBetween(fromIso, toIso).listen((value) {
      trained = value;
      emit();
    }),
    activities.kcalByDayBetween(fromIso, toIso).listen((value) {
      moved = value;
      emit();
    }),
  ];

  ref.onDispose(() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    controller.close();
  });

  yield* controller.stream;
}
