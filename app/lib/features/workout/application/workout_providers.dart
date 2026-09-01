import 'package:disport/app/app.dart';
import 'package:disport/features/workout/data/workout_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workout_providers.g.dart';

@riverpod
WorkoutRepository workoutRepository(Ref ref) =>
    WorkoutRepository(ref.watch(appDatabaseProvider));

/// Gün içinde hareket başına tamamlanan set sayısı.
@riverpod
Stream<Map<String, int>> doneSetCounts(Ref ref, String isoDate) =>
    ref.watch(workoutRepositoryProvider).watchDoneSetCounts(isoDate);

/// Bir hareketin önceki seansındaki gerçekleşmeler.
///
/// Aile argümanı tek `String`: liste ya da kayıt geçilseydi Riverpod her
/// `build`'de yeni bir provider sanardı. Tarih ve id tek anahtarda
/// birleştiriliyor.
@riverpod
Future<List<SetActual>> lastActuals(Ref ref, String key) {
  final separator = key.indexOf('@');
  final exerciseId = key.substring(0, separator);
  final beforeIso = key.substring(separator + 1);

  return ref
      .watch(workoutRepositoryProvider)
      .lastActuals(exerciseId, beforeIso: beforeIso);
}

/// [lastActualsProvider] için anahtar üretir.
String lastActualsKey(String exerciseId, String beforeIso) =>
    '$exerciseId@$beforeIso';

/// Günün kimlikli set kayıtları — Planlanan/Yapılan ekranı (v3 §6.2).
@riverpod
Stream<List<LoggedSet>> dayWorkoutLogs(Ref ref, String isoDate) =>
    ref.watch(workoutRepositoryProvider).watchDayLogs(isoDate);

/// Günün seansları, düzenlenebilir hâlleriyle.
@riverpod
Stream<List<SessionInfo>> daySessions(Ref ref, String isoDate) =>
    ref.watch(workoutRepositoryProvider).watchSessions(isoDate);
