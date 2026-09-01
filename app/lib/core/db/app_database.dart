import 'package:disport/features/catalog/data/equipment_table.dart';
import 'package:disport/features/catalog/data/exercise_table.dart';
import 'package:disport/features/catalog/domain/equipment_kind.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/health/data/lab_tables.dart';
import 'package:disport/features/health/data/metric_definition_table.dart';
import 'package:disport/features/medical/data/medical_tables.dart';
import 'package:disport/features/nutrition/data/nutrition_tables.dart';
import 'package:disport/features/plan/data/plan_meal_item_table.dart';
import 'package:disport/features/plan/data/plan_tables.dart';
import 'package:disport/features/settings/data/profile_table.dart';
import 'package:disport/features/settings/data/weekly_window_table.dart';
import 'package:disport/features/supplements/data/supplement_tables.dart';
import 'package:disport/features/today/data/daily_log_table.dart';
import 'package:disport/features/today/data/daily_rule_table.dart';
import 'package:disport/features/workout/data/exercise_log_table.dart';
import 'package:disport/features/workout/data/workout_session_table.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Uygulamanın tek veritabanı örneği.
///
/// Drift tüm tabloları tek şemada ister; buna karşın tablolar
/// feature'lara aittir (spec 4.4). Bu sınıf yalnızca toplayıcıdır:
/// mantık içermez, feature'ların tablo tanımlarını bir araya getirir.
@DriftDatabase(
  tables: [
    ProfileEntries,
    Exercises,
    Plans,
    PlanDays,
    PlanSlots,
    PlanExercises,
    DailyLogs,
    BodyMetrics,
    ExerciseLogs,
    LabResults,
    LabSchedules,
    DailyRules,
    MetricDefinitions,
    EquipmentItems,
    WeeklyWindows,
    Supplements,
    SupplementLogs,
    Foods,
    FoodPortions,
    MedicalFacts,
    MealBehaviors,
    FavoriteSports,
    PlanMealItems,
    MealEntries,
    Activities,
    ActivityLogs,
    WorkoutSessions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'disport'));

  /// Testlerde bellek içi veritabanı (spec Bölüm 11).
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // Her tablo eklenişinde buraya kademeli bir blok girer; sürüm
      // atlayarak güncellenen bir kurulumda araya giren tüm göçler
      // sırayla çalışsın diye tek tek kontrol edilir.
      if (from < 2) {
        await m.createTable(exercises);
      }
      if (from < 3) {
        await m.createTable(plans);
        await m.createTable(planDays);
        await m.createTable(planSlots);
        await m.createTable(planExercises);
      }
      if (from < 4) {
        await m.createTable(dailyLogs);
        await m.createTable(bodyMetrics);
      }
      if (from < 5) {
        await m.createTable(exerciseLogs);
      }
      if (from < 6) {
        await m.createTable(labResults);
        await m.createTable(labSchedules);
      }
      if (from < 7) {
        await m.createTable(dailyRules);
        await m.addColumn(dailyLogs, dailyLogs.checkedRulesJson);
      }
      if (from < 8) {
        await m.createTable(metricDefinitions);
      }
      if (from < 9) {
        await m.createTable(equipmentItems);
      }
      if (from < 10) {
        await m.createTable(weeklyWindows);
      }
      if (from < 11) {
        await m.createTable(supplements);
        await m.createTable(supplementLogs);
      }
      if (from < 12) {
        await m.addColumn(equipmentItems, equipmentItems.kind);
        await m.addColumn(equipmentItems, equipmentItems.atHome);
        await m.addColumn(equipmentItems, equipmentItems.atGym);

        // Eski "sahibim" işareti ikisine birden yazılıyor: yer bilgisi
        // yokken en geniş yorum doğru olan. Kullanıcının işaretlediği
        // hiçbir şey kaybolmamalı; daralttığımızda "dambılım vardı,
        // nereye gitti" diye sorar.
        await m.database.customStatement(
          'UPDATE equipment_items SET at_home = 1, at_gym = 1 '
          'WHERE is_owned = 1',
        );

        // Türkçe etiketler tipli karşılıklarına çevriliyor. SQL'de
        // yazılamaz: eşleme Türkçe katlaması gerektiriyor ve o Dart
        // tarafında (`TurkishText.fold`). Envanter birkaç düzine satır,
        // tek tek dolaşmak ölçülebilir bir maliyet değil.
        for (final row in await select(equipmentItems).get()) {
          await (update(equipmentItems)..where((t) => t.id.equals(row.id)))
              .write(
                EquipmentItemsCompanion(
                  kind: Value(EquipmentKind.fromLegacyTr(row.label).name),
                ),
              );
        }
      }
      if (from < 13) {
        await m.createTable(foods);
        await m.createTable(foodPortions);
        await m.createTable(mealEntries);
        await m.createTable(activities);
        await m.createTable(activityLogs);
        await m.createTable(workoutSessions);

        await m.addColumn(planExercises, planExercises.speedKmh);
        await m.addColumn(planExercises, planExercises.gradePct);
        await m.addColumn(planExercises, planExercises.effort);
        await m.addColumn(exerciseLogs, exerciseLogs.speedKmh);
        await m.addColumn(exerciseLogs, exerciseLogs.gradePct);
        await m.addColumn(exerciseLogs, exerciseLogs.effort);
      }
      if (from < 14) {
        // Plan slotunun öğün türü. `meal_entries.mealKind` (v13) ile
        // karıştırılmamalı: biri planlanan, öteki yenen.
        await m.addColumn(planSlots, planSlots.mealKind);
      }
      if (from < 15) {
        await m.createTable(medicalFacts);
        await m.createTable(mealBehaviors);
        await m.createTable(favoriteSports);
        await m.createTable(planMealItems);
        // Sütunlar tekrarlı çalışmaya dayanıklı: yarıda kesilen bir
        // yükseltme yeniden denendiğinde "duplicate column" ile
        // çakılmamalı. `createTable` zaten IF NOT EXISTS; addColumn
        // için aynı garantiyi elle veriyoruz.
        await _addColumnIfAbsent(m, supplements, supplements.kind);
        await _addColumnIfAbsent(m, dailyLogs, dailyLogs.waterMl);

        // v2 "sandalye ve basamak herkeste var" sayıyordu; v3 soruyor.
        // Mevcut kurulumda varsayımı koruyarak işaretli açılıyorlar —
        // kullanıcının filtresi bir gecede daralmasın. Taze kurulum
        // tohumu işaretsiz bırakır (EquipmentRepository.seedFrom).
        // Id şeması tohumla aynı (`kind.name`) — aksi hâlde bir sonraki
        // açılışta seedFrom aynı türü ikinci kez eklerdi.
        final now = DateTime.now().millisecondsSinceEpoch;
        for (final kind in ['chair', 'step']) {
          await m.database.customStatement(
            'INSERT OR IGNORE INTO equipment_items '
            '(id, user_id, updated_at, deleted_at, label, kind, '
            ' is_owned, at_home, at_gym, sort_order) '
            "VALUES ('$kind', '', $now, NULL, '$kind', "
            "'$kind', 1, 1, 0, 900)",
          );
        }
      }
    },
  );

  /// `Migrator.addColumn`, sütun zaten varsa `duplicate column` ile
  /// düşer; yarım kalmış bir yükseltmenin tekrarı bunu yaşar. Yalnız o
  /// hata yutulur — başka her SQL hatası yukarı fırlar.
  Future<void> _addColumnIfAbsent(
    Migrator m,
    TableInfo<Table, dynamic> table,
    GeneratedColumn<Object> column,
  ) async {
    try {
      await m.addColumn(table, column);
    } on Exception catch (error) {
      // `SqliteException` doğrudan import edilmiyor (sqlite3 geçişli
      // bağımlılık); mesaj üzerinden ayıklanıyor.
      if (!error.toString().contains('duplicate column')) rethrow;
    }
  }
}
