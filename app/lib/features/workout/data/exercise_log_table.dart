import 'package:disport/core/db/sync_columns.dart';
import 'package:drift/drift.dart';

/// Gerçekte yapılan setler (spec 5.3).
///
/// Plandaki hedef (`plan_exercises`) ile gerçekleşen ayrı tutuluyor:
/// "3 × 10 hedeflendi, 3 × 8 yapıldı" bilgisi ilerlemenin kendisi.
/// M4'te `context.md`'ye giden `setActuals` bloğu ve M5'teki ay sonu
/// tablosu buradan okunur.
@DataClassName('ExerciseLogRow')
class ExerciseLogs extends Table with SyncColumns {
  TextColumn get date => text()();

  /// Hangi plan satırına karşılık geldiği. Plansız yapılan antrenmanda
  /// null olur — kullanıcı katalogdan seçip de çalışabilmeli.
  TextColumn get planExerciseId => text().nullable()();

  TextColumn get exerciseId => text()();

  /// Setin sırası, 0'dan başlar.
  IntColumn get setIndex => integer()();

  IntColumn get reps => integer().nullable()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get durationSec => integer().nullable()();
}
