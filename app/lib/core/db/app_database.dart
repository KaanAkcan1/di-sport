import 'package:disport/features/catalog/data/exercise_table.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/health/data/lab_tables.dart';
import 'package:disport/features/health/data/metric_definition_table.dart';
import 'package:disport/features/plan/data/plan_tables.dart';
import 'package:disport/features/settings/data/profile_table.dart';
import 'package:disport/features/today/data/daily_log_table.dart';
import 'package:disport/features/today/data/daily_rule_table.dart';
import 'package:disport/features/workout/data/exercise_log_table.dart';
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'disport'));

  /// Testlerde bellek içi veritabanı (spec Bölüm 11).
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 8;

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
    },
  );
}
