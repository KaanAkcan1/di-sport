import 'package:disport/app/app.dart';
import 'package:disport/features/plan/application/plan_providers.dart';
import 'package:disport/features/plan/data/plan_editor_repository.dart';
import 'package:disport/features/reminders/application/reminder_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'plan_editor_providers.g.dart';

@riverpod
PlanEditorRepository planEditorRepository(Ref ref) =>
    PlanEditorRepository(ref.watch(appDatabaseProvider));

/// Plan değişikliğinden sonra yapılması gerekenler.
///
/// **Alarmlar hemen yeniden kuruluyor** (M6 kuralı): saat değişip de
/// bildirim eskisine göre çalarsa kullanıcı "çalışmadı" der ve bir
/// daha güvenmez. Bir sonraki açılışı beklemek kabul edilebilir
/// değil.
///
/// Tek yerde toplanması, her editör sayfasının bu iki adımı
/// hatırlamasını gerektirmiyor — biri unutulursa sessizce eski alarm
/// kalırdı.
@riverpod
Future<void> Function() planChanged(Ref ref) => () async {
  ref.invalidate(activePlanProvider);
  await rescheduleQuietly(ref.read(reminderSchedulerProvider));
};
