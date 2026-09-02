import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:disport/app/app.dart';
import 'package:disport/core/notifications/local_notification_service.dart';
import 'package:disport/core/notifications/notification_service.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/health/application/health_providers.dart';
import 'package:disport/features/plan/application/plan_providers.dart';
import 'package:disport/features/reminders/application/reminder_scheduler.dart';
import 'package:disport/features/settings/data/meal_behaviors_repository.dart';
import 'package:disport/features/settings/data/weekly_windows_repository.dart';
import 'package:disport/features/supplements/application/supplement_providers.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_providers.g.dart';

/// Platform bildirim servisi.
///
/// Testlerde `overrideWithValue(FakeNotificationService())` ile
/// değiştirilir; gerçek servis platform kanalına dokunur ve test
/// ortamında çalışmaz.
@riverpod
NotificationService notificationService(Ref ref) => LocalNotificationService();

/// Pencereyi yeniden kurar; hata olursa yutar.
///
/// Arayüzden çağrılan her yerde bu kullanılmalı: bildirim izni
/// reddedilmiş ya da platform kanalı hazır değilse istisna fırlıyor ve
/// bunu sarmalamazsak **profil kaydı** ya da **anahtar değişimi**
/// başarısız görünüyor. Kullanıcının asıl yaptığı iş, alarm kurulumunun
/// yan etkisi yüzünden geri alınmamalı.
/// Zamanlayıcıyı doğrudan alıyor, `ref` değil: çağrı yerleri üç farklı
/// tipte (`Ref`, `WidgetRef`, `ProviderContainer`) ve üçünün de ortak
/// bir üst tipi yok.
///
/// Dil parametre değil burada çözülüyor: çağrı yerlerinin hiçbirinde
/// `BuildContext` yok (bootstrap, ayar anahtarı, profil kaydı) ve her
/// birine dil taşıtmak gürültü olurdu.
Future<void> rescheduleQuietly(
  ReminderScheduler scheduler, {
  Locale? preferred,
}) async {
  try {
    await scheduler.reschedule(DateTime.now(), _localisations(preferred));
  } catch (error, stackTrace) {
    debugPrint('Bildirim kurulumu başarısız: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

/// Seçili dil yoksa cihazın diline düşer; o da desteklenmiyorsa
/// şablon dil (Türkçe) kullanılır.
AppLocalizations _localisations(Locale? preferred) {
  final candidates = [
    ?preferred,
    PlatformDispatcher.instance.locale,
  ];

  for (final locale in candidates) {
    final supported = AppLocalizations.supportedLocales.any(
      (s) => s.languageCode == locale.languageCode,
    );
    if (supported) return lookupAppLocalizations(Locale(locale.languageCode));
  }

  return lookupAppLocalizations(AppLocalizations.supportedLocales.first);
}

@riverpod
ReminderScheduler reminderScheduler(Ref ref) => ReminderScheduler(
  service: ref.watch(notificationServiceProvider),
  plans: ref.watch(planRepositoryProvider),
  today: ref.watch(todayRepositoryProvider),
  labs: ref.watch(labRepositoryProvider),
  profile: ref.watch(profileRepositoryProvider),
  windows: WeeklyWindowsRepository(ref.watch(appDatabaseProvider)),
  supplements: ref.watch(supplementsRepositoryProvider),
  mealBehaviors: MealBehaviorsRepository(ref.watch(appDatabaseProvider)),
);
