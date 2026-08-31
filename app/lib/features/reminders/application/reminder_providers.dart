import 'package:disport/core/notifications/local_notification_service.dart';
import 'package:disport/core/notifications/notification_service.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/health/application/health_providers.dart';
import 'package:disport/features/plan/application/plan_providers.dart';
import 'package:disport/features/reminders/application/reminder_scheduler.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_providers.g.dart';

/// Platform bildirim servisi.
///
/// Testlerde `overrideWithValue(FakeNotificationService())` ile
/// değiştirilir; gerçek servis platform kanalına dokunur ve test
/// ortamında çalışmaz.
@riverpod
NotificationService notificationService(Ref ref) => LocalNotificationService();

@riverpod
ReminderScheduler reminderScheduler(Ref ref) => ReminderScheduler(
  service: ref.watch(notificationServiceProvider),
  plans: ref.watch(planRepositoryProvider),
  today: ref.watch(todayRepositoryProvider),
  labs: ref.watch(labRepositoryProvider),
  profile: ref.watch(profileRepositoryProvider),
);
