import 'package:disport/features/progress/domain/transition_criteria.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('üçü birden sağlanmalı', () {
    expect(
      evaluateTransition(
        latestWeight: 104.5,
        latestPushupMax: 8,
        painFreeConfirmed: true,
      ).allMet,
      isTrue,
    );
  });

  test('105 kilo eşiğe dahil değil', () {
    final t = evaluateTransition(
      latestWeight: 105,
      latestPushupMax: 8,
      painFreeConfirmed: true,
    );
    expect(t.weightOk, isFalse);
    expect(t.allMet, isFalse);
  });

  test('şınav eşiği dahil', () {
    expect(
      evaluateTransition(
        latestWeight: 104.5,
        latestPushupMax: 8,
        painFreeConfirmed: true,
      ).pushupOk,
      isTrue,
    );
    expect(
      evaluateTransition(
        latestWeight: 104.5,
        latestPushupMax: 7,
        painFreeConfirmed: true,
      ).allMet,
      isFalse,
    );
  });

  test('ağrı onayı olmadan geçilmez', () {
    // Bu ölçüt ölçülemez; yalnız kullanıcı bilebilir. Diğer ikisi
    // sağlansa bile onay yoksa koşuya geçilmez (spec 5.5).
    final t = evaluateTransition(
      latestWeight: 100,
      latestPushupMax: 20,
      painFreeConfirmed: false,
    );
    expect(t.weightOk, isTrue);
    expect(t.pushupOk, isTrue);
    expect(t.allMet, isFalse);
  });

  test('veri yoksa sağlanmamış sayılır', () {
    final t = evaluateTransition(
      latestWeight: null,
      latestPushupMax: null,
      painFreeConfirmed: false,
    );
    expect(t.weightOk, isFalse);
    expect(t.pushupOk, isFalse);
    expect(t.allMet, isFalse);
    expect(t.metCount, 0);
  });

  test('metCount kaçının sağlandığını sayar', () {
    expect(
      evaluateTransition(
        latestWeight: 104,
        latestPushupMax: 3,
        painFreeConfirmed: true,
      ).metCount,
      2,
    );
  });
}
