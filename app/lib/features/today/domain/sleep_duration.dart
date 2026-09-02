/// Uyku süresi türetme (v3.1 §2) — saf.
///
/// Yatış *önceki geceye*, kalkış sabaha ait; gece yarısını aşan aralık
/// +24 saatle düzeltilir. Kestirme dakikaları toplam süreye eklenir.
library;

/// `HH:mm` → gün içi dakika; biçim bozuksa null.
int? _minutesOf(String? hhmm) {
  if (hhmm == null) return null;
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(hhmm.trim());
  if (match == null) return null;
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) return null;
  return hour * 60 + minute;
}

/// Yatış-kalkış + kestirme → toplam uyku, saat cinsinden.
///
/// İki saat de geçerli değilse null — yalnız kestirme "uyku süresi"
/// değildir, kullanıcı onu yalnız-süre alanıyla girer. 23:45→06:11
/// gibi gece yarısını aşan aralıklar doğru hesaplanır; 01:00→08:00
/// gibi aşmayanlar da.
double? sleepHoursFrom({
  String? bedTime,
  String? wakeTime,
  int? napMinutes,
}) {
  final bed = _minutesOf(bedTime);
  final wake = _minutesOf(wakeTime);
  if (bed == null || wake == null) return null;

  var night = wake - bed;
  if (night <= 0) night += 24 * 60;

  final total = night + (napMinutes ?? 0);
  return total / 60;
}
