import 'package:disport/core/notifications/local_notification_service.dart';
import 'package:disport/core/notifications/notification_service.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/health/application/health_providers.dart';
import 'package:disport/features/plan/application/plan_providers.dart';
import 'package:disport/features/reminders/application/reminder_scheduler.dart';
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
Future<void> rescheduleQuietly(ReminderScheduler scheduler) async {
  try {
    await scheduler.reschedule(DateTime.now());
  } catch (error, stackTrace) {
    debugPrint('Bildirim kurulumu başarısız: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

@riverpod
ReminderScheduler reminderScheduler(Ref ref) => ReminderScheduler(
  service: ref.watch(notificationServiceProvider),
  plans: ref.watch(planRepositoryProvider),
  today: ref.watch(todayRepositoryProvider),
  labs: ref.watch(labRepositoryProvider),
  profile: ref.watch(profileRepositoryProvider),
);
