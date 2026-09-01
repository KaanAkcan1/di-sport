import 'package:disport/features/reminders/domain/reminder_planner.dart';
import 'package:flutter_test/flutter_test.dart';

List<SlotFact> weekSlots() => [
  for (var d = 0; d < 14; d++) ...[
    (
      date: '2026-09-${(d + 1).toString().padLeft(2, '0')}',
      time: '06:30',
      kind: 'meal',
      label: 'Kahvaltı',
    ),
    (
      date: '2026-09-${(d + 1).toString().padLeft(2, '0')}',
      time: '22:00',
      kind: 'workout',
      label: 'Antrenman',
    ),
  ],
];

/// Test çağrılarının ortak iskeleti; her test yalnız ilgilendiği alanı
/// veriyor, gerisi kapalı.
List<PlannedReminder> plan({
  DateTime? now,
  List<SlotFact> slots = const [],
  Map<String, bool> kindEnabled = const {},
  String? wakeTime,
  List<String> dueLabMarkers = const [],
  DateTime? planEndDate,
  bool twoDayMissStreak = false,
  List<MealTimeFact> mealTimes = const [],
  int maxCount = 60,
}) => planWindow(
  now: now ?? DateTime(2026, 9, 1, 8),
  slots: slots,
  kindEnabled: kindEnabled,
  wakeTime: wakeTime,
  dueLabMarkers: dueLabMarkers,
  planEndDate: planEndDate,
  twoDayMissStreak: twoDayMissStreak,
  mealTimes: mealTimes,
  maxCount: maxCount,
);

void main() {
  group('pencere', () {
    test('yalnız önümüzdeki 7 gün kurulur, geçmiş saatler atlanır', () {
      final r = plan(
        slots: weekSlots(),
        kindEnabled: {'meal': true, 'workout': true},
      );

      // 1 Eylül 06:30 geçmiş → atlanır; 1 Eylül 22:00 kalır.
      expect(r.where((p) => p.fireAt.day == 1), hasLength(1));

      // Pencere anlık: 1 Eylül 08:00 + 7 gün = 8 Eylül 08:00.
      // 8 Eylül 06:30 kahvaltısı içeride, 8 Eylül 22:00 antrenmanı dışarıda.
      expect(
        r.every((p) => p.fireAt.isBefore(DateTime(2026, 9, 8, 8))),
        isTrue,
      );
      expect(
        r.where((p) => p.fireAt.day == 8),
        hasLength(1),
      );
    });

    test('sonuç zaman sırasında', () {
      final r = plan(
        slots: weekSlots(),
        kindEnabled: {'meal': true, 'workout': true},
        wakeTime: '06:11',
      );
      final sorted = [...r]..sort((a, b) => a.fireAt.compareTo(b.fireAt));
      expect(r.map((p) => p.fireAt), sorted.map((p) => p.fireAt));
    });

    test('id çakışması yok', () {
      final r = plan(
        slots: weekSlots(),
        kindEnabled: {'meal': true, 'workout': true},
        wakeTime: '06:30', // tartı 06:45, kahvaltı 06:30 — yakın saatler
        dueLabMarkers: ['Vitamin D'],
        planEndDate: DateTime(2026, 9, 4),
        twoDayMissStreak: true,
      );
      expect(r.map((p) => p.id).toSet(), hasLength(r.length));
    });

    test('id determinist — aynı girdi aynı id', () {
      List<int> ids() => plan(
        slots: weekSlots(),
        kindEnabled: {'workout': true},
      ).map((p) => p.id).toList();

      expect(ids(), ids());
    });

    test('id 32-bit pozitif aralıkta', () {
      // Android bildirim id'si int32; taşan değer platformda patlar.
      final r = plan(slots: weekSlots(), kindEnabled: {'workout': true});
      expect(r.every((p) => p.id > 0 && p.id <= 0x7FFFFFFF), isTrue);
    });

    test('maxCount en yakınları tutar', () {
      final r = plan(
        slots: weekSlots(),
        kindEnabled: {'meal': true, 'workout': true},
        wakeTime: '06:11',
        maxCount: 5,
      );

      expect(r, hasLength(5));
      expect(r.first.fireAt, DateTime(2026, 9, 1, 22));
    });
  });

  group('slot hatırlatmaları', () {
    test('kapalı türler dışarıda kalır', () {
      final r = plan(
        slots: weekSlots(),
        kindEnabled: {'meal': false, 'workout': true},
      );
      expect(r.every((p) => p.text.label != 'Kahvaltı'), isTrue);
      expect(r.any((p) => p.text.label == 'Antrenman'), isTrue);
    });

    test('anahtarı hiç bulunmayan tür kapalı sayılır', () {
      // Yeni bir slot türü eklenirse kullanıcı görmediği bir alarmla
      // karşılaşmamalı; açmak bilinçli bir eylem olmalı.
      final r = plan(slots: weekSlots(), kindEnabled: const {});
      expect(r, isEmpty);
    });

    test('antrenman slotu workout sekmesine yönlendirir', () {
      final r = plan(slots: weekSlots(), kindEnabled: {'workout': true});
      expect(r.first.payload, ReminderPayloads.workout);
    });

    test('öğün slotu Diyet sekmesine yönlendirir', () {
      // v3: öğün bildirimi Diyet'e, antrenman Spor'a. v2'de ikisi de
      // Bugün'e düşüyordu ve sekmeler ayrılınca payload da ayrıldı.
      final r = plan(slots: weekSlots(), kindEnabled: {'meal': true});
      expect(r.first.payload, ReminderPayloads.meal);
      expect(ReminderPayloads.tabIndex[ReminderPayloads.meal], 1);
    });
  });

  group('öğün davranışı saatleri (v3)', () {
    test('tanımlı saat her gün için kurulur ve Diyet sekmesini açar', () {
      final r = plan(
        kindEnabled: {'meal': true},
        mealTimes: [(mealKind: 'ogle', time: '12:30')],
      );

      // 1 Eylül 12:30'dan pencere sonuna kadar günde bir.
      expect(r, hasLength(7));
      expect(r.every((p) => p.payload == ReminderPayloads.meal), isTrue);
      expect(r.first.text.kind, ReminderTextKind.meal);
      expect(r.first.text.marker, 'ogle');
    });

    test('düzen saati varsa plandaki öğün slotları susar', () {
      final r = plan(
        slots: weekSlots(),
        kindEnabled: {'meal': true, 'workout': true},
        mealTimes: [(mealKind: 'kahvalti', time: '07:00')],
      );

      // Slot kaynaklı kahvaltılar (06:30) yok; antrenmanlar duruyor.
      expect(r.where((p) => p.text.kind == ReminderTextKind.slotOther),
          isEmpty);
      expect(
        r.where((p) => p.text.kind == ReminderTextKind.slotWorkout),
        isNotEmpty,
      );
      expect(
        r.where((p) => p.text.kind == ReminderTextKind.meal),
        isNotEmpty,
      );
    });

    test('öğün bildirimi kapalıysa düzen saati de kurulmaz', () {
      final r = plan(
        kindEnabled: {'meal': false},
        mealTimes: [(mealKind: 'ogle', time: '12:30')],
      );
      expect(r, isEmpty);
    });

    test('bozuk saat sessizce atlanır — diğer öğünler etkilenmez', () {
      final r = plan(
        kindEnabled: {'meal': true},
        mealTimes: [
          (mealKind: 'ogle', time: 'öğlen'),
          (mealKind: 'aksam', time: '19:00'),
        ],
      );
      expect(r.every((p) => p.text.marker == 'aksam'), isTrue);
    });
  });

  group('sabah tartısı', () {
    test('uyanma saatinden 15 dakika sonra, her gün', () {
      final r = plan(wakeTime: '06:11');

      expect(r.first.fireAt.hour, 6);
      expect(r.first.fireAt.minute, 26);
      // 2-8 Eylül: bugünün 06:26'sı 08:00'e göre geçmiş.
      expect(r, hasLength(7));
    });

    test('uyanma saati yoksa tartı hatırlatması kurulmaz', () {
      expect(plan(wakeTime: null), isEmpty);
    });

    test('bozuk saat biçimi sessizce atlanır', () {
      // Profil elle düzenlenebilir; geçersiz değer alarm kurmayı
      // tümden çökertmemeli.
      expect(plan(wakeTime: 'sabah'), isEmpty);
    });

    test('gece yarısını geçen ekleme sonraki güne taşar', () {
      final r = plan(now: DateTime(2026, 9, 1, 1), wakeTime: '23:50');
      expect(r.first.fireAt, DateTime(2026, 9, 2, 0, 5));
    });
  });

  group('kaçak uyarısı', () {
    test('iki gün üst üste kaçırılmışsa bu akşam 20:00', () {
      final r = plan(twoDayMissStreak: true);

      expect(r.single.fireAt, DateTime(2026, 9, 1, 20));
      expect(r.single.text.kind, ReminderTextKind.missStreak);
      expect(r.single.payload, ReminderPayloads.today);
    });

    test('akşam 20:00 geçmişse yarına kurulur', () {
      final r = plan(now: DateTime(2026, 9, 1, 21), twoDayMissStreak: true);
      expect(r.single.fireAt, DateTime(2026, 9, 2, 20));
    });

    test('kaçak yoksa uyarı yok', () {
      expect(plan(twoDayMissStreak: false), isEmpty);
    });
  });

  group('tahlil vadesi', () {
    test('marker başına tek hatırlatma, 09:00', () {
      final r = plan(dueLabMarkers: ['Vitamin D', 'B12']);

      expect(r, hasLength(2));
      expect(r.first.fireAt, DateTime(2026, 9, 1, 9));
      expect(r.first.payload, ReminderPayloads.health);
      expect(r.map((p) => p.text.marker).join(), contains('Vitamin D'));
    });

    test('09:00 geçmişse yarına kurulur', () {
      final r = plan(now: DateTime(2026, 9, 1, 10), dueLabMarkers: ['B12']);
      expect(r.single.fireAt, DateTime(2026, 9, 2, 9));
    });
  });

  group('plan bitişi', () {
    test('son üç gün 09:30, bitiş günü dahil', () {
      final r = plan(planEndDate: DateTime(2026, 9, 4));

      expect(r.map((p) => p.fireAt.day), [2, 3, 4]);
      expect(r.every((p) => p.fireAt.hour == 9 && p.fireAt.minute == 30),
          isTrue);
      expect(r.first.payload, ReminderPayloads.plan);
    });

    test('bitiş uzaksa pencereye hiç girmez', () {
      expect(plan(planEndDate: DateTime(2026, 10, 20)), isEmpty);
    });

    test('bitmiş plan yeni hatırlatma üretmez', () {
      expect(plan(planEndDate: DateTime(2026, 8, 20)), isEmpty);
    });
  });
}
