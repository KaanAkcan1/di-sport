import 'package:disport/features/health/data/lab_repository.dart';
import 'package:disport/features/health/domain/lab_share.dart';
import 'package:flutter_test/flutter_test.dart';

LabEntry entry(
  String marker,
  String date,
  double value, {
  double? low,
  double? high,
}) => LabEntry(
  id: '$marker-$date',
  date: date,
  marker: marker,
  value: value,
  unit: 'ng/mL',
  panel: LabPanels.vitamin,
  refLow: low,
  refHigh: high,
);

void main() {
  test('marker başına yalnız son değer, aralık ve tarih yazılır', () {
    final text = buildLabShareText({
      LabPanels.vitamin: [
        entry('D Vitamini', '2026-08-20', 42, low: 30, high: 100),
        entry('D Vitamini', '2026-02-01', 18, low: 30, high: 100),
        entry('B12', '2026-08-20', 350),
      ],
    }, title: 'Tahlil özeti');

    expect(text, contains('Tahlil özeti'));
    expect(text, contains('D Vitamini: 42 ng/mL (30–100) · 2026-08-20'));
    expect(text, isNot(contains('2026-02-01')));
    // Aralıksız satır parantez açmaz.
    expect(text, contains('B12: 350 ng/mL · 2026-08-20'));
  });

  test('boş panel bölüm başlığı üretmez', () {
    final text = buildLabShareText({
      LabPanels.vitamin: const [],
    }, title: 'Özet');
    expect(text.trim(), 'Özet');
  });
}
