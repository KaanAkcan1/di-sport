import 'package:disport/core/notifications/notification_service.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/ai_bridge/domain/context_md_builder.dart'
    show ProfileKeys;
import 'package:disport/features/health/data/lab_repository.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/reminders/application/reminder_texts.dart';
import 'package:disport/features/reminders/domain/reminder_planner.dart';
import 'package:disport/features/settings/data/profile_repository.dart';
import 'package:disport/features/settings/data/weekly_windows_repository.dart';
import 'package:disport/features/today/data/today_repository.dart';

/// Bir bildirim türünün profil anahtarı.
///
/// `notif.workout` gibi. Tür adı slot türüyle aynı (`meal`, `workout`,
/// `walk`…) — böylece plana yeni bir slot türü gelirse ayar anahtarı
/// kendiliğinden oluşur.
String notifKindKey(String kind) => 'notif.$kind';

/// Kullanıcının uyanma saati anahtarı.
///
/// Kendi sabitini tanımlamıyor, profil formunun kaynağına bağlanıyor:
/// iki yerde yazılsaydı biri değiştiğinde sabah tartısı bildirimi
/// sessizce kurulmaz olurdu — hata vermeden, yalnız çalmayarak.
const wakeTimeProfileKey = ProfileKeys.wakeTime;

/// Bildirim kurulabilen slot türleri — ayarlar ekranı bunu listeler.
const notifiableKinds = ['meal', 'workout', 'walk', 'supplement'];

/// Kaynakları toplayıp pencereyi kurar.
///
/// Hesabın kendisi burada değil (`planWindow`, saf ve testli); burası
/// yalnız veriyi toplayıp platforma veriyor. Ayrım kasıtlı: "salı 06:30
/// bildirimi kurulur mu" sorusu veritabanı ve platform olmadan
/// cevaplanabilmeli.
class ReminderScheduler {
  const ReminderScheduler({
    required this.service,
    required this.plans,
    required this.today,
    required this.labs,
    required this.profile,
    required this.windows,
  });

  final NotificationService service;
  final PlanRepository plans;
  final TodayRepository today;
  final LabRepository labs;
  final ProfileRepository profile;

  /// Mesai ve yasaklı saat pencereleri; yasaklı olanlar bildirimleri
  /// eliyor.
  final WeeklyWindowsRepository windows;

  /// Pencereyi baştan kurar; kurulan bildirim sayısını döner.
  ///
  /// [l10n] bildirim metinlerinin dili. Arka planda `BuildContext` yok;
  /// çağıran taraf seçili dili çözüp veriyor (`reminder_providers`).
  Future<int> reschedule(DateTime now, AppLocalizations l10n) async {
    // İzin yoksa hiç uğraşma. Kurulmuş sayılıp sessizce düşen bir
    // bildirim, hiç kurulmamış olandan kötü: kullanıcı alarmına
    // güvenip uyanmayı bekler.
    if (!await service.requestPermissions()) return 0;

    final settings = await profile.all();
    final plan = await plans.activePlan();
    final todayIso = PlanRepository.iso(now);

    final slots = <SlotFact>[
      if (plan != null)
        for (final day in plan.days)
          for (final slot in day.slots)
            (
              date: PlanRepository.iso(day.date),
              time: slot.time,
              kind: slot.kind.name,
              label: slot.label,
            ),
    ];

    final missedStreak = plan == null
        ? 0
        : await today.missedStreak(
            todayIso: todayIso,
            planDayTypes: {
              for (final day in plan.days)
                PlanRepository.iso(day.date): day.type.name,
            },
          );

    final due = await labs.dueSchedules(now);

    final reminders = planWindow(
      now: now,
      slots: slots,
      kindEnabled: {
        for (final kind in notifiableKinds)
          kind: settings[notifKindKey(kind)] == 'true',
      },
      wakeTime: settings[wakeTimeProfileKey],
      dueLabMarkers: [for (final schedule in due) schedule.marker],
      planEndDate: plan?.days.last.date,
      twoDayMissStreak: missedStreak >= 2,
      blockedWindows: await windows.all(),
    );

    // Boş liste de kuruluyor: önceki kurulumun temizlenmesi gerekiyor.
    // Kullanıcı bildirimleri kapattığında eski alarmlar susmalı.
    await service.replaceAll([
      for (final planned in reminders) localiseReminder(planned, l10n),
    ]);
    return reminders.length;
  }
}
