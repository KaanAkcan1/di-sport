import 'package:disport/features/settings/data/weekly_window_table.dart';
import 'package:disport/features/settings/domain/weekly_window.dart';

/// Bildirime dokunulunca açılacak sekme.
///
/// Değerler kabuktaki sekme sırasıyla eşlenir (`app.dart`); string
/// olmalarının nedeni platformun payload'ı metin taşıması.
abstract final class ReminderPayloads {
  static const today = 'today';
  static const workout = 'workout';
  static const plan = 'plan';
  static const health = 'health';

  /// Sekme dizini karşılığı — kabuk bunu okur.
  static const tabIndex = <String, int>{
    today: 0,
    workout: 0, // Antrenman akışı Bugün ekranından başlıyor.
    plan: 1,
    health: 3,
  };
}

/// Planlanmış tek bildirim.
class PendingReminder {
  const PendingReminder({
    required this.id,
    required this.fireAt,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final DateTime fireAt;
  final String title;
  final String body;
  final String payload;
}

/// Plandaki tek slot — hatırlatma için gereken kadarı.
typedef SlotFact = ({String date, String time, String kind, String label});

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
List<PendingReminder> planWindow({
  required DateTime now,
  required List<SlotFact> slots,
  required Map<String, bool> kindEnabled,
  required String? wakeTime,
  required List<String> dueLabMarkers,
  required DateTime? planEndDate,
  required bool twoDayMissStreak,
  List<WeeklyWindow> blockedWindows = const [],
  int windowDays = 7,
  int maxCount = 60,
}) {
  final until = now.add(Duration(days: windowDays));
  final candidates = <PendingReminder>[
    ..._slotReminders(slots, kindEnabled),
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

  return inWindow.length <= maxCount
      ? inWindow
      : inWindow.sublist(0, maxCount);
}

/// 1. Slot hatırlatmaları.
///
/// Kapalı türler hiç üretilmez. Anahtarı bulunmayan tür de kapalı
/// sayılıyor: yeni bir slot türü eklendiğinde kullanıcı hiç açmadığı
/// bir alarmla uyanmamalı.
Iterable<PendingReminder> _slotReminders(
  List<SlotFact> slots,
  Map<String, bool> kindEnabled,
) sync* {
  for (final slot in slots) {
    if (kindEnabled[slot.kind] != true) continue;

    final at = _parseDateTime(slot.date, slot.time);
    if (at == null) continue;

    yield PendingReminder(
      id: _idFor(at, 'slot:${slot.date}:${slot.time}:${slot.kind}'),
      fireAt: at,
      title: slot.label,
      body: slot.kind == 'workout'
          ? 'Antrenman vakti. Hazırsan başlayalım.'
          : 'Programdaki sıradaki adım.',
      payload: slot.kind == 'workout'
          ? ReminderPayloads.workout
          : ReminderPayloads.today,
    );
  }
}

/// 2. Sabah tartısı — uyanmadan 15 dakika sonra.
///
/// Gecikme kasıtlı: uyanır uyanmaz değil, tuvalete gidildikten sonra
/// tartılmak günler arası tutarlılığı artırır.
Iterable<PendingReminder> _weighInReminders(
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

    yield PendingReminder(
      id: _idFor(at, 'weighin'),
      fireAt: at,
      title: 'Sabah tartısı',
      body: 'Aç karnına, aynı koşullarda tartıl.',
      payload: ReminderPayloads.today,
    );
  }
}

/// 3. Kaçak uyarısı.
///
/// PDF'in "iki gün üst üste kaçırma" kuralı. Akşam 20:00 seçildi:
/// gün bitmeden hâlâ telafi edilebilecek bir saat.
Iterable<PendingReminder> _missStreakReminder(
  DateTime now,
  bool twoDayMissStreak,
) sync* {
  if (!twoDayMissStreak) return;

  final at = _nextOccurrence(now, hour: 20);
  yield PendingReminder(
    id: _idFor(at, 'miss'),
    fireAt: at,
    title: 'Zincir kopuyor',
    body: 'Antrenmanı iki gün üst üste kaçırdın. Bugün kısa bir şey '
        'yapmak, hiç yapmamaktan iyi.',
    payload: ReminderPayloads.today,
  );
}

/// 4. Tahlil vadesi.
///
/// Marker başına **tek** hatırlatma: vadesi geçmiş her tahlil için her
/// gün bildirim atmak kullanıcıyı bildirimleri tümden kapatmaya iter.
Iterable<PendingReminder> _dueLabReminders(
  DateTime now,
  List<String> markers,
) sync* {
  if (markers.isEmpty) return;
  final at = _nextOccurrence(now, hour: 9);

  for (final marker in markers) {
    yield PendingReminder(
      id: _idFor(at, 'lab:$marker'),
      fireAt: at,
      title: 'Tahlil zamanı',
      body: '$marker tahlilinin vakti geldi.',
      payload: ReminderPayloads.health,
    );
  }
}

/// 5. Plan bitiyor — son üç gün, bitiş günü dahil.
///
/// Üç gün, yeni planı AI'dan isteyip gözden geçirmeye yetecek kadar
/// önceden haber vermek için; plan bittiği gün haber vermek geç olurdu.
Iterable<PendingReminder> _planEndingReminders(DateTime? planEndDate) sync* {
  if (planEndDate == null) return;

  for (var back = 2; back >= 0; back--) {
    final day = DateTime(
      planEndDate.year,
      planEndDate.month,
      planEndDate.day - back,
      9,
      30,
    );
    yield PendingReminder(
      id: _idFor(day, 'planend'),
      fireAt: day,
      title: 'Plan bitiyor',
      body: back == 0
          ? 'Plan bugün bitiyor. Yeni plan için bağlam dosyasını al.'
          : 'Plan $back gün sonra bitiyor. Yeni planı hazırlamanın vakti.',
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
