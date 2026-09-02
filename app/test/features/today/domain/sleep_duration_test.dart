import 'package:disport/features/today/domain/sleep_duration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sleepHoursFrom', () {
    test('gece yarısını aşan aralık doğru hesaplanır', () {
      // 23:45 → 06:11 = 6 sa 26 dk
      expect(
        sleepHoursFrom(bedTime: '23:45', wakeTime: '06:11'),
        closeTo(6 + 26 / 60, 0.001),
      );
    });

    test('gece yarısından sonra yatış da doğru', () {
      expect(sleepHoursFrom(bedTime: '01:00', wakeTime: '08:00'), 7.0);
    });

    test('kestirme toplam süreye eklenir', () {
      expect(
        sleepHoursFrom(bedTime: '23:00', wakeTime: '06:00', napMinutes: 30),
        7.5,
      );
    });

    test('saatlerden biri yoksa null — yalnız kestirme süre değildir', () {
      expect(sleepHoursFrom(bedTime: '23:00', wakeTime: null), isNull);
      expect(sleepHoursFrom(bedTime: null, wakeTime: '06:00'), isNull);
      expect(sleepHoursFrom(napMinutes: 45), isNull);
    });

    test('bozuk biçim null döner', () {
      expect(sleepHoursFrom(bedTime: '25:00', wakeTime: '06:00'), isNull);
      expect(sleepHoursFrom(bedTime: 'dün', wakeTime: '06:00'), isNull);
      expect(sleepHoursFrom(bedTime: '23:75', wakeTime: '06:00'), isNull);
    });

    test('tek haneli saat kabul edilir', () {
      expect(sleepHoursFrom(bedTime: '23:00', wakeTime: '6:00'), 7.0);
    });
  });
}
