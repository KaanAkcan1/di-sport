import 'package:disport/features/settings/data/weekly_window_table.dart';
import 'package:disport/features/settings/domain/weekly_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WeeklyWindow window({
    String id = 'w',
    int weekday = 1,
    String start = '08:00',
    String end = '17:00',
    String kind = WindowKinds.work,
  }) => WeeklyWindow(
    id: id,
    weekday: weekday,
    startTime: start,
    endTime: end,
    kind: kind,
  );

  group('containsMinute', () {
    test('başlangıç dahil, bitiş hariç', () {
      final w = window();
      // 17:00 dışarıda: yoksa 17:00-18:00 penceresiyle çakışır.
      expect(w.containsMinute(8 * 60), isTrue);
      expect(w.containsMinute(16 * 60 + 59), isTrue);
      expect(w.containsMinute(17 * 60), isFalse);
      expect(w.containsMinute(7 * 60 + 59), isFalse);
    });

    test('gece yarısını aşan pencere iki ucu da kapsar', () {
      // Uyku penceresi neredeyse her zaman böyle.
      final w = window(start: '23:00', end: '06:00');
      expect(w.wrapsMidnight, isTrue);
      expect(w.containsMinute(23 * 60 + 30), isTrue);
      expect(w.containsMinute(2 * 60), isTrue);
      expect(w.containsMinute(12 * 60), isFalse);
    });
  });

  group('isWithinWindow', () {
    test('aynı gün ve aralıkta ise doğru', () {
      // 2026-09-07 Pazartesi.
      expect(
        isWithinWindow(
          moment: DateTime(2026, 9, 7, 10),
          windows: [window()],
          kind: WindowKinds.work,
        ),
        isTrue,
      );
    });

    test('başka gün ise yanlış', () {
      expect(
        isWithinWindow(
          moment: DateTime(2026, 9, 8, 10), // Salı
          windows: [window()],
          kind: WindowKinds.work,
        ),
        isFalse,
      );
    });

    test('tür eşleşmezse sayılmaz', () {
      expect(
        isWithinWindow(
          moment: DateTime(2026, 9, 7, 10),
          windows: [window()],
          kind: WindowKinds.blocked,
        ),
        isFalse,
      );
    });

    test('gece yarısını aşan pencere ertesi güne sarkar', () {
      // Pazartesi 23:00-06:00 penceresi Salı 02:00'yi kapsamalı.
      final w = window(start: '23:00', end: '06:00');
      expect(
        isWithinWindow(
          moment: DateTime(2026, 9, 8, 2),
          windows: [w],
          kind: WindowKinds.work,
        ),
        isTrue,
      );
      // Salı 08:00 kapsanmamalı.
      expect(
        isWithinWindow(
          moment: DateTime(2026, 9, 8, 8),
          windows: [w],
          kind: WindowKinds.work,
        ),
        isFalse,
      );
    });

    test('Pazar gecesi Pazartesiye sarkar', () {
      // Hafta sonu sınırı: weekday 7'nin ertesi günü 1.
      final w = window(weekday: 7, start: '23:00', end: '06:00');
      expect(
        isWithinWindow(
          moment: DateTime(2026, 9, 7, 3), // Pazartesi 03:00
          windows: [w],
          kind: WindowKinds.work,
        ),
        isTrue,
      );
    });

    test('bozuk saat tüm günü yasaklamaz', () {
      // Geçersiz bir kayıt yüzünden kullanıcı gününü kaybetmemeli.
      final w = window(start: 'sabah', end: 'akşam');
      expect(
        isWithinWindow(
          moment: DateTime(2026, 9, 7, 10),
          windows: [w],
          kind: WindowKinds.work,
        ),
        isFalse,
      );
    });

    test('pencere yoksa hiçbir an kapsanmaz', () {
      expect(
        isWithinWindow(
          moment: DateTime(2026, 9, 7, 10),
          windows: const [],
          kind: WindowKinds.work,
        ),
        isFalse,
      );
    });
  });
}
