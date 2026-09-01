import 'package:disport/features/supplements/domain/dose_adherence.dart';
import 'package:disport/features/supplements/domain/supplement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 9, 1); // Salı

  const metformin = Supplement(
    id: 'met',
    name: 'Metformin',
    kind: SupplementKind.medication,
    times: ['08:00', '20:00'],
  );
  const vitamin = Supplement(
    id: 'vit',
    name: 'D Vitamini',
    times: ['08:00'],
    // Yalnız pazartesi.
    weekdays: {1},
  );

  test('7 gün, eskiden bugüne sıralı döner', () {
    final days = doseAdherence(
      supplements: const [metformin],
      takenByDate: const {},
      today: today,
    );
    expect(days, hasLength(7));
    expect(days.first.date, '2026-08-26');
    expect(days.last.date, '2026-09-01');
  });

  test('tam · eksik · plansız günler doğru sınıflanır', () {
    final days = doseAdherence(
      supplements: const [metformin],
      takenByDate: const {
        '2026-08-31': {'met@08:00', 'met@20:00'},
        '2026-08-30': {'met@08:00'},
      },
      today: today,
    );

    final byDate = {for (final d in days) d.date: d};
    expect(byDate['2026-08-31']!.full, isTrue);
    expect(byDate['2026-08-30']!.partial, isTrue);
    expect(byDate['2026-08-29']!.full, isFalse);
    expect(byDate['2026-08-29']!.partial, isFalse);
    expect(byDate['2026-08-29']!.planned, 2);
  });

  test('hafta günü süzgeci planlanan sayıya girer', () {
    final days = doseAdherence(
      supplements: const [vitamin],
      takenByDate: const {},
      today: today,
    );
    final byDate = {for (final d in days) d.date: d};
    // 31 Ağustos 2026 pazartesi — planlı; salı değil.
    expect(byDate['2026-08-31']!.planned, 1);
    expect(byDate['2026-09-01']!.unscheduled, isTrue);
  });

  test('tanım yoksa bütün günler plansız — şerit çizilmez', () {
    final days = doseAdherence(
      supplements: const [],
      takenByDate: const {},
      today: today,
    );
    expect(days.every((d) => d.unscheduled), isTrue);
  });
}
