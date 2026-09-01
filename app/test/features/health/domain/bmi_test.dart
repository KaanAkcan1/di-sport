import 'package:disport/features/health/domain/bmi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VKİ kilo ve boydan hesaplanır', () {
    expect(
      bodyMassIndex(weightKg: 92.5, heightCm: 182),
      closeTo(27.9, 0.05),
    );
  });

  test('kilo ya da boy yoksa null — uydurma değer yok', () {
    expect(bodyMassIndex(weightKg: null, heightCm: 182), isNull);
    expect(bodyMassIndex(weightKg: 92, heightCm: null), isNull);
    expect(bodyMassIndex(weightKg: 92, heightCm: 0), isNull);
  });

  test('DSÖ eşikleri — sınır değerler üst sınıfa düşer', () {
    expect(BmiClass.of(18.4), BmiClass.underweight);
    expect(BmiClass.of(18.5), BmiClass.normal);
    expect(BmiClass.of(24.9), BmiClass.normal);
    expect(BmiClass.of(25), BmiClass.overweight);
    expect(BmiClass.of(29.9), BmiClass.overweight);
    expect(BmiClass.of(30), BmiClass.obese);
  });
}
