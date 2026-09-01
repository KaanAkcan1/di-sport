import 'package:disport/core/notifications/notification_service.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/reminders/domain/reminder_planner.dart';

/// Planlanmış bildirimi kullanıcının dilinde metne çevirir.
///
/// **Neden burada:** `reminder_planner` saf — zamanlama mantığı emülatör
/// açmadan test edilebilsin diye hiçbir Flutter bağımlılığı yok. Metin
/// ise dile bağlı ve `AppLocalizations` ister. Sınır burası: planlayıcı
/// "ne zaman ve ne türde", bu dosya "hangi sözcüklerle".
///
/// Slot etiketi ve tahlil adı **çevrilmez** — onlar kullanıcının kendi
/// verisi, arayüz metni değil.
PendingReminder localiseReminder(
  PlannedReminder planned,
  AppLocalizations l10n,
) {
  final text = planned.text;

  final (title, body) = switch (text.kind) {
    ReminderTextKind.slotWorkout => (
      text.label ?? l10n.reminderSlotFallbackTitle,
      l10n.reminderSlotWorkoutBody,
    ),
    ReminderTextKind.slotOther => (
      text.label ?? l10n.reminderSlotFallbackTitle,
      l10n.reminderSlotOtherBody,
    ),
    ReminderTextKind.weighIn => (
      l10n.reminderWeighInTitle,
      l10n.reminderWeighInBody,
    ),
    ReminderTextKind.missStreak => (
      l10n.reminderMissStreakTitle,
      l10n.reminderMissStreakBody,
    ),
    ReminderTextKind.dueLab => (
      l10n.reminderDueLabTitle,
      l10n.reminderDueLabBody(text.marker ?? ''),
    ),
    ReminderTextKind.planEnding => (
      l10n.reminderPlanEndingTitle,
      (text.daysLeft ?? 0) == 0
          ? l10n.reminderPlanEndingToday
          : l10n.reminderPlanEndingIn(text.daysLeft!),
    ),
  };

  return PendingReminder(
    id: planned.id,
    fireAt: planned.fireAt,
    title: title,
    body: body,
    payload: planned.payload,
  );
}
