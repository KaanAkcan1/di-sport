import 'package:disport/features/progress/domain/weekly_summary.dart';
import 'package:flutter_test/flutter_test.dart';

String iso(int index) => '2026-09-${(index + 1).toString().padLeft(2, '0')}';

List<DayFact> twoWeeks() => [
  for (var i = 0; i < 14; i++)
    (
      date: iso(i),
      dayType: i % 7 == 0 || i % 7 == 2 || i % 7 == 5 ? 'gym' : 'home',
      workoutDone: i != 3, // 4. gün kaçırıldı
      noAlcoholSugar: i != 8, // 9. gün kaçak
    ),
];

List<WeightPoint> descendingWeights() => [
  for (var i = 0; i < 14; i++) (date: iso(i), value: 110.0 - i * 0.1),
];

void main() {
  test('iki hafta ortalama, sayaç ve kaçakla özetlenir', () {
    final weeks = summarizeWeeks(
      days: twoWeeks(),
      weights: descendingWeights(),
      gymTarget: 3,
      homeTarget: 4,
    );

    expect(weeks, hasLength(2));
    expect(weeks[0].weekIndex, 1);

    expect(weeks[0].avgWeight, closeTo(109.7, 0.001));
    expect(weeks[0].gymDone, 3);
    expect(weeks[0].homeDone, 3); // dördünden biri kaçırıldı
    expect(weeks[0].slipDays, 0);
    expect(weeks[0].deltaFromPrevWeek, isNull);

    expect(weeks[1].slipDays, 1);
    expect(weeks[1].deltaFromPrevWeek, closeTo(-0.7, 0.001));
  });

  test('hedefler her haftaya taşınır', () {
    final weeks = summarizeWeeks(
      days: twoWeeks(),
      weights: descendingWeights(),
      gymTarget: 3,
      homeTarget: 4,
    );
    expect(weeks.every((w) => w.gymTarget == 3 && w.homeTarget == 4), isTrue);
  });

  test('eksik hafta yarım dilim olarak da özetlenir', () {
    // 10 gün = 1 tam hafta + 3 günlük yarım hafta. Yarım hafta atılmaz;
    // kullanıcı içinde bulunduğu haftayı görebilmeli.
    final weeks = summarizeWeeks(
      days: twoWeeks().take(10).toList(),
      weights: descendingWeights().take(10).toList(),
      gymTarget: 3,
      homeTarget: 4,
    );
    expect(weeks, hasLength(2));
    expect(weeks[1].dayCount, 3);
    expect(weeks[1].isPartial, isTrue);
    expect(weeks[0].isPartial, isFalse);
  });

  test('tartı yoksa ortalama null, sayaçlar yine çalışır', () {
    final weeks = summarizeWeeks(
      days: twoWeeks().take(7).toList(),
      weights: const [],
      gymTarget: 3,
      homeTarget: 4,
    );
    expect(weeks.single.avgWeight, isNull);
    expect(weeks.single.deltaFromPrevWeek, isNull);
    expect(weeks.single.gymDone, 3);
  });

  test('dinlenme günü hedef sayacına girmez', () {
    final days = [
      for (var i = 0; i < 7; i++)
        (
          date: iso(i),
          dayType: i < 2 ? 'rest' : 'home',
          workoutDone: false,
          noAlcoholSugar: true,
        ),
    ];
    final weeks = summarizeWeeks(
      days: days,
      weights: const [],
      gymTarget: 0,
      homeTarget: 5,
    );
    expect(weeks.single.homeDone, 0);
    expect(weeks.single.restDays, 2);
  });

  test('gün yoksa hiç hafta üretilmez', () {
    expect(
      summarizeWeeks(
        days: const [],
        weights: const [],
        gymTarget: 3,
        homeTarget: 4,
      ),
      isEmpty,
    );
  });
}
