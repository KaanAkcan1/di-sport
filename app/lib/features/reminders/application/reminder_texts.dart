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
/// Öğün hatırlatmasının başlığı — `MealKind` adından çeviriye.
///
/// Bilinmeyen ad olduğu gibi döner: planlayıcıdan gelen değer bizim
/// verimiz ama bildirim katmanında hata fırlatmak alarmı susturur;
/// yanlış başlıklı alarm, hiç çalmayan alarmdan iyidir.
String _mealTitle(AppLocalizations l10n, String mealKind) =>
    switch (mealKind) {
      'kahvalti' => l10n.mealKahvalti,
      'araOgun' => l10n.mealAraOgun,
      'ogle' => l10n.mealOgle,
      'ikindi' => l10n.mealIkindi,
      'aksam' => l10n.mealAksam,
      'gece' => l10n.mealGece,
      _ => mealKind,
    };

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
    ReminderTextKind.supplement => (
      text.label ?? l10n.reminderSlotFallbackTitle,
      (text.marker ?? '').isEmpty
          ? l10n.reminderSupplementBody
          : l10n.reminderSupplementBodyWithDose(text.marker!),
    ),
    ReminderTextKind.meal => (
      _mealTitle(l10n, text.marker ?? ''),
      l10n.reminderMealBody,
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
