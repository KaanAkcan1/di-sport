import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../plan_fixtures.dart';

void main() {
  late AppDatabase db;
  late PlanRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PlanRepository(db);
  });
  tearDown(() => db.close());

  group('iso', () {
    test('tarihi yyyy-MM-dd biçimine çevirir, tek haneleri doldurur', () {
      expect(PlanRepository.iso(DateTime(2026, 8, 31)), '2026-08-31');
      expect(PlanRepository.iso(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });

  group('yazma', () {
    test('insertFullPlan planı gün, slot ve hareketleriyle kaydeder', () async {
      await repo.insertFullPlan(fixturePlan());

      final plan = await repo.activePlan();
      expect(plan!.title, 'Test Planı');
      expect(plan.days, hasLength(7));
      expect(plan.days.first.slots, hasLength(3));
      expect(plan.days.first.exercises, hasLength(2));
      expect(plan.goals.proteinG, 170);
      expect(plan.rules.forbidden, ['alkol']);
      expect(plan.sourceRaw, '{}');
    });

    test('yeni plan eskisini pasifleştirir', () async {
      await repo.insertFullPlan(fixturePlan());
      await repo.insertFullPlan(
        fixturePlan(id: 'pl2', title: 'İkinci', start: DateTime(2026, 9, 7)),
      );

      final plan = await repo.activePlan();
      expect(plan!.id, 'pl2');
      expect(plan.title, 'İkinci');
    });

    test('plan yokken activePlan null', () async {
      expect(await repo.activePlan(), isNull);
    });
  });

  group('gün okuma', () {
    setUp(() => repo.insertFullPlan(fixturePlan()));

    test('watchDay o günü slot ve hareketleriyle verir', () async {
      final day = await repo.watchDay('2026-08-31').first;

      expect(day!.type, PlanDayType.gym);
      expect(day.weekIndex, 1);
      expect(day.headline, 'Hafta 1 notu');
      expect(day.dinnerSuggestion, 'Izgara tavuk + salata');
      expect(day.exercises.first.exerciseId, 'incline_pushup');
    });

    test('slotlar saate göre sıralı gelir', () async {
      final day = await repo.watchDay('2026-08-31').first;
      expect(day!.slots.map((s) => s.time), ['06:30', '12:00', '22:00']);
    });

    test('plan dışındaki tarih için null', () async {
      expect(await repo.watchDay('2027-01-01').first, isNull);
    });

    test('yalnız aktif planın günü döner', () async {
      // Aynı tarihi kapsayan ikinci bir plan eklenince eski plan pasifleşir;
      // Bugün ekranı eski planın gününü göstermemeli.
      await repo.insertFullPlan(
        fixturePlan(id: 'pl2', title: 'İkinci'),
      );
      final day = await repo.watchDay('2026-08-31').first;
      expect(day!.id, startsWith('pl2'));
    });
  });

  group('türetilen bilgiler', () {
    setUp(() => repo.insertFullPlan(fixturePlan(weeks: 4)));

    test('gün sayısı hafta sayısıyla tutarlı', () async {
      final plan = await repo.activePlan();
      expect(plan!.days, hasLength(28));
      expect(plan.dayCount, 28);
      expect(plan.endDate, DateTime(2026, 9, 27));
    });

    test('dayAt tarihe göre günü bulur', () async {
      final plan = await repo.activePlan();
      expect(plan!.dayAt(DateTime(2026, 9, 5))!.date, DateTime(2026, 9, 5));
      expect(plan.dayAt(DateTime(2030, 1, 1)), isNull);
    });

    test('planın kapsadığı tarih aralığı sorgulanabilir', () async {
      expect(await repo.hasPlanFor('2026-09-05'), isTrue);
      expect(await repo.hasPlanFor('2026-10-05'), isFalse);
    });
  });

  test('silinen plan aktif sayılmaz', () async {
    await repo.insertFullPlan(fixturePlan());
    await repo.deletePlan('pl1');
    expect(await repo.activePlan(), isNull);
    expect(await repo.watchDay('2026-08-31').first, isNull);
  });
}
