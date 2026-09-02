import 'dart:ui' show Locale;

import 'package:disport/core/db/app_database.dart';
import 'package:disport/core/notifications/notification_service.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/health/data/lab_repository.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/reminders/application/reminder_scheduler.dart';
import 'package:disport/features/reminders/domain/reminder_planner.dart';
import 'package:disport/features/settings/data/meal_behaviors_repository.dart';
import 'package:disport/features/settings/data/profile_repository.dart';
import 'package:disport/features/settings/data/weekly_windows_repository.dart';
import 'package:disport/features/supplements/data/supplements_repository.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../plan/plan_fixtures.dart';

/// `replaceAll` çağrılarını kaydeden sahte servis.
class FakeNotificationService implements NotificationService {
  final calls = <List<PendingReminder>>[];
  var exactAllowed = true;
  var permissionGranted = true;

  List<PendingReminder> get lastCall => calls.last;

  @override
  Future<bool> canScheduleExact() async => exactAllowed;

  @override
  Future<bool> requestExactPermission() async => exactAllowed;

  @override
  Future<bool> requestPermissions() async => permissionGranted;

  @override
  Future<void> replaceAll(List<PendingReminder> reminders) async =>
      calls.add(reminders);

  @override
  Future<int> pendingCount() async => calls.isEmpty ? 0 : lastCall.length;
}

void main() {
  // Bildirim metinleri artık dile bağlı; test Türkçeyi sabitliyor.
  final l10n = lookupAppLocalizations(const Locale('tr'));

  late AppDatabase db;
  late FakeNotificationService service;
  late ReminderScheduler scheduler;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = FakeNotificationService();
    scheduler = ReminderScheduler(
      service: service,
      plans: PlanRepository(db),
      today: TodayRepository(db),
      labs: LabRepository(db),
      profile: ProfileRepository(db),
      windows: WeeklyWindowsRepository(db),
      supplements: SupplementsRepository(db),
      mealBehaviors: MealBehaviorsRepository(db),
    );
  });
  tearDown(() => db.close());

  /// 1 Eylül'den başlayan, her günü antrenman ve öğün slotlu bir plan.
  Future<void> seedPlan() => PlanRepository(
    db,
  ).insertFullPlan(fixturePlan(start: DateTime(2026, 9, 1)));

  // Plan fixture'ı 2026-09-01'de başlıyor; pencere o günden sayılıyor.
  final now = DateTime(2026, 9, 1, 8);

  group('kurulum', () {
    test('izin verilmezse hiç bildirim kurulmaz', () async {
      service.permissionGranted = false;
      await seedPlan();
      await ProfileRepository(db).set(notifKindKey('workout'), 'true');

      final count = await scheduler.reschedule(now, l10n);

      expect(count, 0);
      // Servise hiç dokunulmamalı: izinsiz kurulan bildirim sessizce
      // kaybolur, kullanıcı alarm kurulduğunu sanır.
      expect(service.calls, isEmpty);
    });

    test('plan slotları pencereye girer', () async {
      await seedPlan();
      await ProfileRepository(db).set(notifKindKey('workout'), 'true');

      final count = await scheduler.reschedule(now, l10n);

      expect(count, greaterThan(0));
      expect(service.calls, hasLength(1));
      expect(
        service.lastCall.every(
          (r) => r.fireAt.isAfter(now) &&
              r.fireAt.isBefore(now.add(const Duration(days: 7))),
        ),
        isTrue,
      );
    });

    test('kapalı slot türleri kurulmaz', () async {
      await seedPlan();
      // Hiçbir slot türü açılmadı.
      await scheduler.reschedule(now, l10n);

      expect(
        service.lastCall.where(
          (r) =>
              r.payload == ReminderPayloads.workout ||
              r.title.contains('yumurta'),
        ),
        isEmpty,
      );
    });

    test('plan bitiş uyarısı tür anahtarlarına bağlı değil', () async {
      // Kullanıcı öğün bildirimlerini kapatmış olabilir; bu, planının
      // bittiğini haber vermemek anlamına gelmez — o bildirim
      // olmadan uygulama sessizce boş plana düşer.
      await seedPlan();
      await scheduler.reschedule(now, l10n);

      final ending = service.lastCall.where(
        (r) => r.payload == ReminderPayloads.plan,
      );
      // Fixture planı 7 Eylül'de bitiyor: 5, 6, 7 Eylül.
      expect(ending.map((r) => r.fireAt.day), [5, 6, 7]);
    });

    test('ikinci çağrı listeyi ikiye katlamaz', () async {
      await seedPlan();
      await ProfileRepository(db).set(notifKindKey('workout'), 'true');

      await scheduler.reschedule(now, l10n);
      final first = service.lastCall.length;

      await scheduler.reschedule(now, l10n);

      expect(service.calls, hasLength(2));
      expect(service.lastCall, hasLength(first));
      // Aynı girdiyle aynı id'ler: `replaceAll` idempotent.
      expect(
        service.calls[0].map((r) => r.id),
        service.calls[1].map((r) => r.id),
      );
    });
  });

  group('kaynaklar', () {
    test('uyanma saati tartı bildirimi üretir', () async {
      await ProfileRepository(db).set('wakeTime', '06:30');

      await scheduler.reschedule(now, l10n);

      expect(
        service.lastCall.where((r) => r.title == 'Sabah tartısı'),
        isNotEmpty,
      );
    });

    test('vadesi gelen tahlil bildirimi üretir', () async {
      await LabRepository(db).setSchedule('Vitamin D', 3);

      await scheduler.reschedule(now, l10n);

      final lab = service.lastCall.singleWhere(
        (r) => r.payload == ReminderPayloads.health,
      );
      expect(lab.body, contains('Vitamin D'));
    });

    test('plan yokken de tartı bildirimi kurulabilir', () async {
      // Plan almadan önce de kullanıcı tartılıyor; alarmın plana
      // bağımlı olması bu akışı kırardı.
      await ProfileRepository(db).set('wakeTime', '07:00');

      final count = await scheduler.reschedule(now, l10n);
      expect(count, 7);
    });

    test('hiç kaynak yoksa boş liste kurulur', () async {
      final count = await scheduler.reschedule(now, l10n);

      expect(count, 0);
      // Yine de çağrılır: önceki kurulumun temizlenmesi gerekiyor.
      expect(service.calls, hasLength(1));
      expect(service.lastCall, isEmpty);
    });
  });

  group('yasaklı pencereler', () {
    test('yasaklı saate düşen bildirim kurulmaz', () async {
      await ProfileRepository(db).set('wakeTime', '06:30');
      // Tartı 06:45'e denk geliyor; Salı sabahı uygun değil.
      await WeeklyWindowsRepository(db).addForDays(
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
        startTime: '06:00',
        endTime: '08:00',
        kind: WindowKinds.blocked,
      );

      final count = await scheduler.reschedule(now, l10n);
      expect(count, 0);
    });

    test('pencere dışındaki bildirim etkilenmez', () async {
      await ProfileRepository(db).set('wakeTime', '06:30');
      await WeeklyWindowsRepository(db).addForDays(
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
        startTime: '13:00',
        endTime: '14:00',
        kind: WindowKinds.blocked,
      );

      final count = await scheduler.reschedule(now, l10n);
      expect(count, 7);
    });

    test('mesai penceresi bildirimleri elemiyor', () async {
      // Mesai "işteyim" demek, "rahatsız etme" değil — insan işte de
      // yemek yiyor. Yalnız `blocked` eliyor.
      await ProfileRepository(db).set('wakeTime', '06:30');
      await WeeklyWindowsRepository(db).addForDays(
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
        startTime: '06:00',
        endTime: '08:00',
        kind: WindowKinds.work,
      );

      expect(await scheduler.reschedule(now, l10n), 7);
    });
  });
}
