import 'package:disport/features/health/domain/bmi.dart';
import 'package:disport/features/health/domain/checkup_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 9, 1);

  CheckupAdvice adviceFor(List<CheckupAdvice> list, CheckupTest test) =>
      list.singleWhere((a) => a.test == test);

  test('genç ve sağlıklıda tam panel 30 ay, lipit 60 ay', () {
    final advice = checkupAdvice(today: today, age: 32);
    expect(adviceFor(advice, CheckupTest.fullPanel).intervalMonths, 30);
    expect(adviceFor(advice, CheckupTest.lipid).intervalMonths, 60);
    // HbA1c kuralı yalnız kronik riskte var.
    expect(
      advice.any((a) => a.test == CheckupTest.hba1c),
      isFalse,
    );
  });

  test('40 yaş üstü tam panel yıllığa iner', () {
    final advice = checkupAdvice(today: today, age: 41);
    expect(adviceFor(advice, CheckupTest.fullPanel).intervalMonths, 12);
  });

  test('insülin direnci HbA1c kuralını 6 aya açar', () {
    final advice = checkupAdvice(
      today: today,
      age: 32,
      conditionIds: {'insulinResistance'},
    );
    expect(adviceFor(advice, CheckupTest.hba1c).intervalMonths, 6);
  });

  test('VKİ 30 üstü de HbA1c kuralını açar — obezite kronik risk', () {
    expect(BmiClass.of(31), BmiClass.obese);
    final advice = checkupAdvice(today: today, age: 32, bmi: 31);
    expect(advice.any((a) => a.test == CheckupTest.hba1c), isTrue);
  });

  test('sınırda lipit sonucu lipiti yıllığa indirir', () {
    final advice = checkupAdvice(
      today: today,
      age: 32,
      lastLipidBorderline: true,
    );
    expect(adviceFor(advice, CheckupTest.lipid).intervalMonths, 12);
  });

  test('hiç yapılmamış tahlil vakti-geldi sayılır', () {
    final advice = checkupAdvice(today: today, age: 32);
    expect(adviceFor(advice, CheckupTest.vitaminDB12).due, isTrue);
  });

  test('yeni yapılmış tahlil kalan ayı söyler ve sıralamada arkaya düşer', () {
    final advice = checkupAdvice(
      today: today,
      age: 32,
      lastDone: {CheckupTest.vitaminDB12: DateTime(2026, 6, 1)},
    );
    final vit = adviceFor(advice, CheckupTest.vitaminDB12);
    expect(vit.due, isFalse);
    expect(vit.monthsLeft, 9);
    // Vakti gelenler önce.
    expect(advice.first.due, isTrue);
    expect(advice.last.due, isFalse);
  });

  test('koşullu kullanıcıda tam panel de yıllık — kronik izlem', () {
    final advice = checkupAdvice(
      today: today,
      age: 32,
      conditionIds: {'hypertension'},
    );
    expect(adviceFor(advice, CheckupTest.fullPanel).intervalMonths, 12);
  });
}
