/// Haftalık bir zaman penceresi — saf model.
///
/// `domain/` katmanında çünkü hem `reminders` hem `ai_bridge` bunu
/// okuyor ve ikisi de veri katmanına bağlanmamalı.
class WeeklyWindow {
  const WeeklyWindow({
    required this.id,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.kind,
    this.label = '',
  });

  final String id;

  /// 1 = Pazartesi … 7 = Pazar.
  final int weekday;

  /// `HH:mm`.
  final String startTime;
  final String endTime;

  final String kind;
  final String label;

  int get startMinutes => minutesOf(startTime);
  int get endMinutes => minutesOf(endTime);

  /// Gece yarısını aşan pencere — 23:00-06:00 gibi.
  ///
  /// Uyku penceresi neredeyse her zaman böyle; desteklenmezse kullanıcı
  /// onu iki parçaya bölmek zorunda kalır.
  bool get wrapsMidnight => endMinutes <= startMinutes;

  /// Verilen dakika bu pencerenin içinde mi.
  ///
  /// Başlangıç dahil, bitiş hariç: 08:00-17:00 penceresi 17:00'yi
  /// kapsamaz, yoksa 17:00-18:00 penceresiyle çakışır.
  bool containsMinute(int minute) => wrapsMidnight
      ? minute >= startMinutes || minute < endMinutes
      : minute >= startMinutes && minute < endMinutes;

  /// `HH:mm` → gün içi dakika. Bozuk biçim `-1` döner ve hiçbir şeyi
  /// kapsamaz — geçersiz bir kayıt yüzünden tüm gün yasaklanmamalı.
  static int minutesOf(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return -1;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return -1;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return -1;
    return hour * 60 + minute;
  }
}

/// Verilen an bir pencerenin içinde mi — saf.
///
/// Alarm penceresi ve plan doğrulaması bunu kullanıyor.
bool isWithinWindow({
  required DateTime moment,
  required List<WeeklyWindow> windows,
  required String kind,
}) {
  final minute = moment.hour * 60 + moment.minute;

  for (final window in windows) {
    if (window.kind != kind) continue;
    if (window.startMinutes < 0 || window.endMinutes < 0) continue;

    // Gece yarısını aşan pencere ertesi güne sarkıyor: 23:00-06:00
    // Pazartesi penceresi Salı 02:00'yi de kapsar.
    final previousDay = moment.weekday == 1 ? 7 : moment.weekday - 1;

    final sameDay = window.weekday == moment.weekday;
    final carriedOver = window.wrapsMidnight && window.weekday == previousDay;

    if (!sameDay && !carriedOver) continue;

    if (carriedOver && !sameDay) {
      if (minute < window.endMinutes) return true;
      continue;
    }
    if (window.containsMinute(minute)) return true;
  }
  return false;
}
