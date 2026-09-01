import 'package:disport/features/settings/data/weekly_window_table.dart';
import 'package:disport/features/settings/domain/weekly_window.dart';

/// Bildirime dokunulunca açılacak sekme.
///
/// Değerler kabuktaki sekme sırasıyla eşlenir (`app.dart`); string
/// olmalarının nedeni platformun payload'ı metin taşıması.
abstract final class ReminderPayloads {
  static const today = 'today';
  static const meal = 'meal';
  static const workout = 'workout';
  static const plan = 'plan';
  static const health = 'health';

  /// Sekme dizini karşılığı — kabuk bunu okur (v3 sırası:
  /// Ana Sayfa · Diyet · Spor · Sağlık · Daha).
  ///
  /// `meal` v3'te ayrıldı: öğün bildirimi Diyet'e, antrenman Spor'a
  /// gitmeli. v2'de ikisi de Bugün'e düşüyordu ve doğruydu; sekmeler
  /// ayrılınca payload da ayrıldı.
  static const tabIndex = <String, int>{
    today: 0,
    meal: 1,
    workout: 2,
    plan: 2,
    health: 3,
  };
}

/// Bildirim metninin türü.
///
/// Planlayıcı metnin **kendisini** değil türünü üretiyor: metin
/// kullanıcının diline bağlı ve bu saf katmanın `AppLocalizations`
/// görmesi doğru olmaz. Çeviri zamanlayıcıda yapılıyor
/// (`reminder_texts.dart`).
enum ReminderTextKind {
  slotWorkout,
  slotOther,
  weighIn,
  missStreak,
  dueLab,
  planEnding,
  supplement,

  /// Öğün davranışından gelen günlük öğün hatırlatması (v3 §3.4).
  /// `marker` öğünün `MealKind` adını taşır; metin katmanı çevirir.
  meal,
}

/// Metnin türü ve içine gireceği **veri**.
///
/// [label] ve [marker] kullanıcının kendi verisi (slot etiketi, tahlil
/// adı) — çevrilmez, olduğu gibi geçer.
class ReminderText {
  const ReminderText(this.kind, {this.label, this.marker, this.daysLeft});

  final ReminderTextKind kind;
  final String? label;
  final String? marker;
  final int? daysLeft;
}

/// Planlanmış tek bildirim — metni henüz çözülmemiş hâli.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.fireAt,
    required this.text,
    required this.payload,
  });

  final int id;
  final DateTime fireAt;
  final ReminderText text;
  final String payload;
}

/// Plandaki tek slot — hatırlatma için gereken kadarı.
typedef SlotFact = ({String date, String time, String kind, String label});

/// Bir öğünün günlük saati — Günlük Düzen'deki davranıştan (v3 §3.4).
///
/// `external` öğünler buraya hiç girmez: yemekhane saatini hatırlatmak
/// anlamsız. Saati boş olanlar da girmez — esnek öğüne alarm kurulmaz.
typedef MealTimeFact = ({String mealKind, String time});

/// Bir takviye — hatırlatma için gereken kadarı.
///
/// Saf katman `Supplement` modelini görmüyor: planlayıcının feature'a
/// bağımlı olmaması, "salı 08:00 alarmı kurulur mu" sorusunun tek
/// başına cevaplanabilmesi demek.
typedef SupplementFact = ({
  String id,
  String name,
  String doseLabel,
  List<String> times,
  Set<int> weekdays,
});

/// Önümüzdeki pencereye düşen bildirimleri hesaplar — saf fonksiyon.
///
/// **Neden pencere:** iOS aynı anda en fazla 64 bekleyen bildirim tutar
/// (spec 8). Dört haftalık planın tüm slotlarını kurmak bu sınırı aşar
/// ve iOS fazlasını sessizce atar — hangisini attığını da söylemez.
/// Bunun yerine yalnız yakın gelecek kurulur, uygulama her açılışta
/// pencereyi yeniden kurar.
///
/// **Neden anlık pencere (takvim günü değil):** akşam 23:00'te açılan
/// uygulama "bugün + 6 gün" derse yarından sonrasını neredeyse hiç
/// kapsamaz. `now`'dan itibaren [windowDays] × 24 saat, açılış saatinden
/// bağımsız aynı kapsamı verir.
///
/// **Neden saf:** zamanlama mantığı burada, platform çağrısı ayrı
/// (`NotificationService`). Böylece "salı günü 06:30 bildirimi kurulur
/// mu" sorusu emülatör açmadan cevaplanıyor.
///
/// [maxCount] pencereye sığan bildirim sayısını sınırlar; aşılırsa en
/// yakın tarihliler kalır — kullanıcı en çok bugünkü alarmına muhtaç.
List<PlannedReminder> planWindow({
  required DateTime now,
  required List<SlotFact> slots,
  required Map<String, bool> kindEnabled,
  required String? wakeTime,
  required List<String> dueLabMarkers,
  required DateTime? planEndDate,
  required bool twoDayMissStreak,
  List<SupplementFact> supplements = const [],
  List<MealTimeFact> mealTimes = const [],
  List<WeeklyWindow> blockedWindows = const [],
  int windowDays = 7,
  int maxCount = 60,
}) {
  final until = now.add(Duration(days: windowDays));
  final candidates = <PlannedReminder>[
    // Günlük Düzen'de öğün saati tanımlıysa öğün hatırlatmasının
    // kaynağı odur; plan slotlarındaki öğünler o zaman sessiz kalır —
    // 12:00 (düzen) ve 12:30 (plan) diye iki alarm çalmasın.
    ..._slotReminders(slots, kindEnabled, skipMeals: mealTimes.isNotEmpty),
    ..._mealTimeReminders(now, mealTimes, kindEnabled, windowDays),
    ..._weighInReminders(now, wakeTime, windowDays),
    ..._missStreakReminder(now, twoDayMissStreak),
    ..._dueLabReminders(now, dueLabMarkers),
    ..._planEndingReminders(planEndDate),
  ];

  final inWindow =
      candidates
          .where(
            (r) =>
                r.fireAt.isAfter(now) &&
                r.fireAt.isBefore(until) &&
                // Yasaklı pencereye düşen bildirim hiç kurulmuyor:
                // kullanıcı "bu saatlerde uygun değilim" dediyse alarmın
                // yine de çalması o ayarı anlamsız kılardı.
                !isWithinWindow(
                  moment: r.fireAt,
                  windows: blockedWindows,
                  kind: WindowKinds.blocked,
                ),
          )
          .toList()
        ..sort((a, b) => a.fireAt.compareTo(b.fireAt));

  // Takviyeler yasaklı pencere süzgecinden **sonra** ekleniyor.
  //
  // Gerekçe: "bu saatlerde uygun değilim" mesai için doğru bir kural
  // ama ilaç saati mesaiye kurban edilmez. Toplantıdayken antrenman
  // hatırlatması istemeyen kullanıcı, tansiyon hapını da atlamak
  // istemiyor.
  final withSupplements =
      [
        ...inWindow,
        ..._supplementReminders(now, supplements, windowDays)
            .where((r) => r.fireAt.isAfter(now) && r.fireAt.isBefore(until)),
      ]..sort((a, b) => a.fireAt.compareTo(b.fireAt));

  return withSupplements.length <= maxCount
      ? withSupplements
      : withSupplements.sublist(0, maxCount);
}

/// 6. Takviye ve ilaç hatırlatmaları.
///
/// Hafta günü süzgeci burada uygulanıyor; saatsiz takviye hiç bildirim
/// üretmiyor (kullanıcı saat girmediyse hatırlatma da istememiştir).
Iterable<PlannedReminder> _supplementReminders(
  DateTime now,
  List<SupplementFact> supplements,
  int windowDays,
) sync* {
  for (var offset = 0; offset <= windowDays; offset++) {
    final day = DateTime(now.year, now.month, now.day + offset);

    for (final supplement in supplements) {
      final activeToday =
          supplement.weekdays.isEmpty ||
          supplement.weekdays.contains(day.weekday);
      if (!activeToday) continue;

      for (final time in supplement.times) {
        final at = _parseTime(time);
        if (at == null) continue;

        final fireAt = DateTime(
          day.year,
          day.month,
          day.day,
          at.hour,
          at.minute,
        );

        yield PlannedReminder(
          id: _idFor(fireAt, 'supplement:${supplement.id}:$time'),
          fireAt: fireAt,
          text: ReminderText(
            ReminderTextKind.supplement,
            label: supplement.name,
            marker: supplement.doseLabel,
          ),
          payload: ReminderPayloads.today,
        );
      }
    }
  }
}

/// 1. Slot hatırlatmaları.
///
/// Kapalı türler hiç üretilmez. Anahtarı bulunmayan tür de kapalı
/// sayılıyor: yeni bir slot türü eklendiğinde kullanıcı hiç açmadığı
/// bir alarmla uyanmamalı.
Iterable<PlannedReminder> _slotReminders(
  List<SlotFact> slots,
  Map<String, bool> kindEnabled, {
  bool skipMeals = false,
}) sync* {
  for (final slot in slots) {
    if (kindEnabled[slot.kind] != true) continue;
    if (skipMeals && slot.kind == 'meal') continue;

    final at = _parseDateTime(slot.date, slot.time);
    if (at == null) continue;

    final isWorkout = slot.kind == 'workout';
    yield PlannedReminder(
      id: _idFor(at, 'slot:${slot.date}:${slot.time}:${slot.kind}'),
      fireAt: at,
      text: ReminderText(
        isWorkout ? ReminderTextKind.slotWorkout : ReminderTextKind.slotOther,
        label: slot.label,
      ),
      payload: switch (slot.kind) {
        'workout' => ReminderPayloads.workout,
        'meal' => ReminderPayloads.meal,
        _ => ReminderPayloads.today,
      },
    );
  }
}

/// 1b. Öğün davranışı saatleri — her gün aynı saatte (v3 §3.4).
///
/// Öğün hatırlatmaları da `meal` anahtarına bağlı: kullanıcı öğün
/// bildirimini kapattıysa düzen saati de çalmaz.
Iterable<PlannedReminder> _mealTimeReminders(
  DateTime now,
  List<MealTimeFact> mealTimes,
  Map<String, bool> kindEnabled,
  int windowDays,
) sync* {
  if (kindEnabled['meal'] != true) return;

  for (final meal in mealTimes) {
    final time = _parseTime(meal.time);
    if (time == null) continue;

    for (var offset = 0; offset <= windowDays; offset++) {
      final day = DateTime(now.year, now.month, now.day + offset);
      final at = day.add(Duration(hours: time.hour, minutes: time.minute));

      yield PlannedReminder(
        id: _idFor(at, 'mealtime:${meal.mealKind}'),
        fireAt: at,
        text: ReminderText(ReminderTextKind.meal, marker: meal.mealKind),
        payload: ReminderPayloads.meal,
      );
    }
  }
}

/// 2. Sabah tartısı — uyanmadan 15 dakika sonra.
///
/// Gecikme kasıtlı: uyanır uyanmaz değil, tuvalete gidildikten sonra
/// tartılmak günler arası tutarlılığı artırır.
Iterable<PlannedReminder> _weighInReminders(
  DateTime now,
  String? wakeTime,
  int windowDays,
) sync* {
  final wake = _parseTime(wakeTime);
  if (wake == null) return;

  for (var offset = 0; offset <= windowDays; offset++) {
    final day = DateTime(now.year, now.month, now.day + offset);
    final at = day
        .add(Duration(hours: wake.hour, minutes: wake.minute + 15));

    yield PlannedReminder(
      id: _idFor(at, 'weighin'),
      fireAt: at,
      text: const ReminderText(ReminderTextKind.weighIn),
      payload: ReminderPayloads.today,
    );
  }
}

/// 3. Kaçak uyarısı.
///
/// PDF'in "iki gün üst üste kaçırma" kuralı. Akşam 20:00 seçildi:
/// gün bitmeden hâlâ telafi edilebilecek bir saat.
Iterable<PlannedReminder> _missStreakReminder(
  DateTime now,
  bool twoDayMissStreak,
) sync* {
  if (!twoDayMissStreak) return;

  final at = _nextOccurrence(now, hour: 20);
  yield PlannedReminder(
    id: _idFor(at, 'miss'),
    fireAt: at,
    text: const ReminderText(ReminderTextKind.missStreak),
    payload: ReminderPayloads.today,
  );
}

/// 4. Tahlil vadesi.
///
/// Marker başına **tek** hatırlatma: vadesi geçmiş her tahlil için her
/// gün bildirim atmak kullanıcıyı bildirimleri tümden kapatmaya iter.
Iterable<PlannedReminder> _dueLabReminders(
  DateTime now,
  List<String> markers,
) sync* {
  if (markers.isEmpty) return;
  final at = _nextOccurrence(now, hour: 9);

  for (final marker in markers) {
    yield PlannedReminder(
      id: _idFor(at, 'lab:$marker'),
      fireAt: at,
      text: ReminderText(ReminderTextKind.dueLab, marker: marker),
      payload: ReminderPayloads.health,
    );
  }
}

/// 5. Plan bitiyor — son üç gün, bitiş günü dahil.
///
/// Üç gün, yeni planı AI'dan isteyip gözden geçirmeye yetecek kadar
/// önceden haber vermek için; plan bittiği gün haber vermek geç olurdu.
Iterable<PlannedReminder> _planEndingReminders(DateTime? planEndDate) sync* {
  if (planEndDate == null) return;

  for (var back = 2; back >= 0; back--) {
    final day = DateTime(
      planEndDate.year,
      planEndDate.month,
      planEndDate.day - back,
      9,
      30,
    );
    yield PlannedReminder(
      id: _idFor(day, 'planend'),
      fireAt: day,
      text: ReminderText(ReminderTextKind.planEnding, daysLeft: back),
      payload: ReminderPayloads.plan,
    );
  }
}

/// Bugün ya da yarın, verilen saatte.
DateTime _nextOccurrence(DateTime now, {required int hour}) {
  final today = DateTime(now.year, now.month, now.day, hour);
  return today.isAfter(now)
      ? today
      : DateTime(now.year, now.month, now.day + 1, hour);
}

DateTime? _parseDateTime(String isoDate, String time) {
  final clock = _parseTime(time);
  if (clock == null) return null;

  final date = DateTime.tryParse(isoDate);
  if (date == null) return null;

  return DateTime(date.year, date.month, date.day, clock.hour, clock.minute);
}

/// `HH:mm` ayrıştırır; biçim bozuksa `null`.
///
/// Profil elle de düzenlenebiliyor; geçersiz bir saat tüm alarm kurma
/// işlemini çökertmemeli — o satır atlanır, gerisi kurulur.
({int hour, int minute})? _parseTime(String? value) {
  if (value == null) return null;

  final parts = value.split(':');
  if (parts.length != 2) return null;

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

  return (hour: hour, minute: minute);
}

/// Determinist bildirim kimliği.
///
/// Android bildirim id'si int32; taşarsa platform çağrısı patlar.
/// Dakika damgası ile ayırıcının karışımı alınıyor — aynı dakikaya
/// düşen iki farklı bildirim (06:30 kahvaltı, 06:30 tartı) çakışmasın.
///
/// `String.hashCode` yerine elle FNV-1a: Dart'ın hash'i çalışmalar
/// arasında sabit olmak zorunda değil, bu ise testte sabitlenebilir
/// olmalı.
int _idFor(DateTime fireAt, String discriminator) {
  var hash = 0x811C9DC5;
  for (final unit in discriminator.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }

  final minutes = fireAt.millisecondsSinceEpoch ~/ 60000;
  // 0 geçerli bir id ama "kurulmadı" ile karıştırılmasın diye 1'den
  // başlatılıyor.
  return (((minutes * 31) ^ hash) & 0x7FFFFFFF) | 1;
}
