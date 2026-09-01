import 'package:disport/features/plan/domain/full_plan.dart';

/// Takvim hücresinin dolgu durumu.
///
/// Saf bir sınıflandırma: ekrandan bağımsız, testi doğrudan yazılıyor.
/// Renk eşlemesi sunum katmanında — burada yalnız *anlam* var.
enum DayCellFill {
  /// Günün her planlanmış işi işaretlenmiş.
  done,

  /// Bir kısmı işaretlenmiş; ya da bugün, henüz bitmedi.
  partial,

  /// Gün geçti ve hiçbir şey işaretlenmemiş — gerçek bir boşluk.
  empty,

  /// Planlanmış iş yok: serbest gün.
  free,

  /// Henüz gelmedi.
  future,
}

/// Bir günün takvimdeki dolgusunu belirler.
///
/// **Bugün asla `empty` olmaz.** Sabah 09:00'da hiçbir şey
/// işaretlenmemiş olması bir boşluk değil, günün henüz başlaması. Kırmızı
/// bir hücre kullanıcıya yanlış sinyal verirdi.
///
/// M9'da kalori dengesi bu eşlemenin üstüne biniyor (spec §2a: yeşile
/// çalan = bütçe altı, kızıla çalan = üstü). M12'de ton kaynağı yalnız
/// doluluk.
DayCellFill resolveDayFill({
  required FullPlanDay day,
  required int checkedCount,
  required DateTime today,
}) {
  final date = DateTime(day.date.year, day.date.month, day.date.day);
  final base = DateTime(today.year, today.month, today.day);

  if (date.isAfter(base)) return DayCellFill.future;

  final total = day.slots.length;
  if (total == 0 || day.isFullyFree) return DayCellFill.free;

  if (checkedCount >= total) return DayCellFill.done;
  if (checkedCount > 0) return DayCellFill.partial;

  // Gün bugünse henüz bitmedi; boşluk saymak erken.
  return date.isAtSameMomentAs(base)
      ? DayCellFill.partial
      : DayCellFill.empty;
}
