import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/workout/application/energy_source_adapter.dart';
import 'package:disport/features/workout/data/workout_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WorkoutRepository(db);
  });

  tearDown(() => db.close());

  group('seans kaydı', () {
    test('aynı gün ikinci çağrı yeni seans açmaz', () async {
      // Kullanıcı antrenman ekranına gün içinde birkaç kez giriyor;
      // her girişte yeni seans açmak süreyi ve kaloriyi katlardı.
      final first = await repo.startSession('2026-09-01');
      final second = await repo.startSession('2026-09-01');

      expect(second, first);
      expect(await db.select(db.workoutSessions).get(), hasLength(1));
    });

    test('bitirilmemiş seans süre listesine girmez', () async {
      // Uygulamayı açık unutan kullanıcıya 9 saatlik antrenman
      // yazılmamalı.
      await repo.startSession('2026-09-01');

      expect(await repo.watchSessionDurations('2026-09-01').first, isEmpty);
    });

    test('bitirilen seansın süresi ölçülür', () async {
      final start = DateTime(2026, 9, 1, 18);
      await repo.startSession('2026-09-01', now: start);
      await repo.endSession(
        '2026-09-01',
        now: start.add(const Duration(minutes: 52)),
      );

      final durations = await repo.watchSessionDurations('2026-09-01').first;
      expect(durations.single, const Duration(minutes: 52));
    });

    test('açık seans yokken bitirmek bir şey bozmaz', () async {
      await repo.endSession('2026-09-01');
      expect(await repo.watchSessionDurations('2026-09-01').first, isEmpty);
    });
  });

  group('EnergySourceAdapter', () {
    test('52 dakika, 109 kg → ≈ 472 kcal', () async {
      final start = DateTime(2026, 9, 1, 18);
      await repo.startSession('2026-09-01', now: start);
      await repo.endSession(
        '2026-09-01',
        now: start.add(const Duration(minutes: 52)),
      );

      final source = EnergySourceAdapter(repo, weightKg: 109);
      expect(await source.burnedOn('2026-09-01').first, closeTo(472, 5));
    });

    test('seans yoksa sıfır — tahmin uydurulmaz', () async {
      // Setlerin toplam süresi seansın süresi değil; aradan geçen
      // dinlenmeyi bilmeden kalori üretmek uydurma olurdu.
      await repo.logSet(
        isoDate: '2026-09-01',
        exerciseId: 'pushup',
        setIndex: 0,
        reps: 10,
      );

      final source = EnergySourceAdapter(repo, weightKg: 109);
      expect(await source.burnedOn('2026-09-01').first, 0);
    });

    test('aynı gün iki seans toplanır', () async {
      final morning = DateTime(2026, 9, 1, 8);
      await repo.startSession('2026-09-01', now: morning);
      await repo.endSession(
        '2026-09-01',
        now: morning.add(const Duration(minutes: 30)),
      );

      final evening = DateTime(2026, 9, 1, 19);
      await repo.startSession('2026-09-01', now: evening);
      await repo.endSession(
        '2026-09-01',
        now: evening.add(const Duration(minutes: 30)),
      );

      final source = EnergySourceAdapter(repo, weightKg: 100);
      // 5 MET × 100 kg × 1 saat = 500.
      expect(await source.burnedOn('2026-09-01').first, closeTo(500, 2));
    });

    test('kilo arttıkça harcama artar', () async {
      final start = DateTime(2026, 9, 1, 18);
      await repo.startSession('2026-09-01', now: start);
      await repo.endSession(
        '2026-09-01',
        now: start.add(const Duration(hours: 1)),
      );

      final light = await EnergySourceAdapter(
        repo,
        weightKg: 70,
      ).burnedOn('2026-09-01').first;
      final heavy = await EnergySourceAdapter(
        repo,
        weightKg: 110,
      ).burnedOn('2026-09-01').first;

      expect(heavy, greaterThan(light));
    });

    test('burnedBetween günlere göre gruplar', () async {
      for (final day in ['2026-09-01', '2026-09-03']) {
        final start = DateTime(2026, 9, int.parse(day.split('-').last), 18);
        await repo.startSession(day, now: start);
        await repo.endSession(
          day,
          now: start.add(const Duration(minutes: 60)),
        );
      }

      final source = EnergySourceAdapter(repo, weightKg: 100);
      final totals = await source
          .burnedBetween('2026-09-01', '2026-09-05')
          .first;

      expect(totals.keys, containsAll(['2026-09-01', '2026-09-03']));
      expect(totals['2026-09-01'], closeTo(500, 2));
      // Antrenman yapılmayan gün haritada yok.
      expect(totals.containsKey('2026-09-02'), isFalse);
    });
  });
}
