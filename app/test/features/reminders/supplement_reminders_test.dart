import 'package:disport/features/reminders/domain/reminder_planner.dart';
import 'package:disport/features/settings/data/weekly_window_table.dart';
import 'package:disport/features/settings/domain/weekly_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 1, 6); // Salı sabah 06:00

  List<PlannedReminder> plan({
    List<SupplementFact> supplements = const [],
    List<WeeklyWindow> blocked = const [],
    int windowDays = 7,
  }) => planWindow(
    now: now,
    slots: const [],
    kindEnabled: const {},
    wakeTime: null,
    dueLabMarkers: const [],
    planEndDate: null,
    twoDayMissStreak: false,
    supplements: supplements,
    blockedWindows: blocked,
    windowDays: windowDays,
  );

  const daily = (
    id: 's1',
    name: 'D Vitamini',
    doseLabel: '1000 IU',
    times: ['08:00', '21:30'],
    weekdays: <int>{},
  );

  test('takviyesiz pencerede bildirim yok', () {
    expect(plan(), isEmpty);
  });

  test('iki saatlik takviye yedi günde 14 bildirim üretir', () {
    // 1 Eylül 06:00'dan 8 Eylül 06:00'a: her günün 08:00 ve 21:30'u
    // pencereye giriyor, son günün ikisi de dışarıda kalıyor.
    final reminders = plan(supplements: [daily]);
    expect(reminders, hasLength(14));
  });

  test('saatsiz takviye hiç bildirim üretmez', () {
    // Saat girmeyen kullanıcı hatırlatma da istememiştir.
    final reminders = plan(
      supplements: const [
        (
          id: 's2',
          name: 'Magnezyum',
          doseLabel: '',
          times: <String>[],
          weekdays: <int>{},
        ),
      ],
    );
    expect(reminders, isEmpty);
  });

  test('hafta günü süzgeci uygulanır', () {
    // Yalnız pazartesi (ISO 1). 1-8 Eylül aralığında bir pazartesi var:
    // 7 Eylül.
    final reminders = plan(
      supplements: const [
        (
          id: 's3',
          name: 'B12',
          doseLabel: '',
          times: ['09:00'],
          weekdays: {1},
        ),
      ],
    );

    expect(reminders, hasLength(1));
    expect(reminders.single.fireAt.weekday, DateTime.monday);
  });

  test('metin türü ve veri taşınır — ad çevrilmez', () {
    final reminder = plan(supplements: [daily]).first;
    expect(reminder.text.kind, ReminderTextKind.supplement);
    expect(reminder.text.label, 'D Vitamini');
    expect(reminder.text.marker, '1000 IU');
  });

  test('determinist id — aynı girdi aynı kimlik', () {
    final first = plan(supplements: [daily]).map((r) => r.id).toList();
    final second = plan(supplements: [daily]).map((r) => r.id).toList();
    expect(first, second);
  });

  test('kimlikler çakışmıyor', () {
    final ids = plan(supplements: [daily]).map((r) => r.id).toSet();
    expect(ids, hasLength(14));
  });

  group('yasaklı pencere', () {
    final blocked = [
      WeeklyWindow(
        id: 'w1',
        weekday: DateTime.tuesday,
        startTime: '07:00',
        endTime: '23:00',
        kind: WindowKinds.blocked,
        label: 'Mesai',
      ),
    ];

    test('ilaç saati mesaiye kurban edilmez', () {
      // "Bu saatlerde uygun değilim" antrenman için doğru bir kural ama
      // tansiyon hapı için değil. Takviye süzgeçten muaf.
      final reminders = plan(supplements: [daily], blocked: blocked);
      final tuesday = reminders.where(
        (r) => r.fireAt.weekday == DateTime.tuesday,
      );

      expect(tuesday, isNotEmpty);
    });

    test('yasaklı pencere diğer türleri yine eliyor', () {
      // Muafiyet takviyeye özel; kural genel olarak yürürlükte.
      final reminders = planWindow(
        now: now,
        slots: const [
          (
            date: '2026-09-01',
            time: '12:00',
            kind: 'meal',
            label: 'Öğle',
          ),
        ],
        kindEnabled: const {'meal': true},
        wakeTime: null,
        dueLabMarkers: const [],
        planEndDate: null,
        twoDayMissStreak: false,
        blockedWindows: blocked,
      );

      expect(reminders, isEmpty);
    });
  });

  test('takviyeler diğer bildirimlerle saate göre harmanlanır', () {
    final reminders = planWindow(
      now: now,
      slots: const [
        (
          date: '2026-09-01',
          time: '12:00',
          kind: 'meal',
          label: 'Öğle',
        ),
      ],
      kindEnabled: const {'meal': true},
      wakeTime: null,
      dueLabMarkers: const [],
      planEndDate: null,
      twoDayMissStreak: false,
      supplements: [daily],
    );

    final times = reminders.map((r) => r.fireAt).toList();
    for (var i = 1; i < times.length; i++) {
      expect(
        times[i].isBefore(times[i - 1]),
        isFalse,
        reason: 'sıralama bozuk',
      );
    }
  });
}
