import 'package:disport/features/progress/domain/weight_trend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final points = [
    (date: '2026-09-01', value: 110.0),
    (date: '2026-09-02', value: 109.0),
    (date: '2026-09-03', value: 111.0),
    (date: '2026-09-04', value: 108.0),
  ];

  group('movingAverage', () {
    test('pencere dolmadan eldeki noktalarla ortalar', () {
      final avg = movingAverage(points, window: 3);

      expect(avg.first.avg, 110.0); // tek nokta
      expect(avg[1].avg, closeTo(109.5, 0.001)); // (110+109)/2
      expect(avg[2].avg, closeTo(110.0, 0.001)); // (110+109+111)/3
      expect(avg[3].avg, closeTo(109.333, 0.001)); // (109+111+108)/3
    });

    test('tarihler girdiyle birebir korunur', () {
      final avg = movingAverage(points, window: 3);
      expect(
        avg.map((p) => p.date),
        points.map((p) => p.date),
      );
    });

    test('boş girdi boş çıktı verir', () {
      expect(movingAverage([]), isEmpty);
    });

    test('pencere 1 iken girdiyi aynen döner', () {
      final avg = movingAverage(points, window: 1);
      expect(avg.map((p) => p.avg), points.map((p) => p.value));
    });

    test('eksik günler atlanmaz — pencere gün değil nokta sayar', () {
      // 2 ve 3 Eylül tartılmamış. Hareketli ortalama takvim boşluğunu
      // doldurmaya çalışmaz; kullanıcı tartılmadığı günü kilo almış
      // saymamalı (spec 6, "günlük rakama tepki verme").
      final sparse = [
        (date: '2026-09-01', value: 110.0),
        (date: '2026-09-04', value: 108.0),
      ];
      final avg = movingAverage(sparse, window: 7);
      expect(avg, hasLength(2));
      expect(avg.last.avg, closeTo(109.0, 0.001));
    });
  });
}
