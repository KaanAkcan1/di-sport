import 'package:disport/features/today/application/day_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dateKeyOf', () {
    test('tek haneleri doldurur', () {
      expect(dateKeyOf(DateTime(2026, 9, 1)), '2026-09-01');
      expect(dateKeyOf(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('saat bileşeni anahtarı değiştirmez', () {
      // Aile argümanının `String` olmasının nedeni bu: `DateTime` saat
      // taşıyor ve iki örnek `==` ile asla eşit olmaz — provider
      // sonsuza dek yeniden kurulurdu.
      expect(
        dateKeyOf(DateTime(2026, 9, 1, 6, 30)),
        dateKeyOf(DateTime(2026, 9, 1, 23, 59)),
      );
    });
  });

  group('positionOf', () {
    const today = '2026-09-01';

    test('dün geçmiş', () {
      expect(positionOf('2026-08-31', today), DayPosition.past);
    });

    test('bugün bugün', () {
      expect(positionOf(today, today), DayPosition.today);
    });

    test('yarın gelecek', () {
      expect(positionOf('2026-09-02', today), DayPosition.future);
    });

    test('yıl ve ay sınırında da doğru', () {
      // Karşılaştırma sözlük sırasıyla: `yyyy-MM-dd` biçimi bunu
      // güvenli kılıyor ve tarih ayrıştırmaya gerek bırakmıyor.
      expect(positionOf('2025-12-31', '2026-01-01'), DayPosition.past);
      expect(positionOf('2026-02-01', '2026-01-31'), DayPosition.future);
    });
  });
}
