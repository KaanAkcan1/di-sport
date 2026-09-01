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
/// Kalori dengesi bu eşlemenin **üstüne** biniyor, yerine geçmiyor —
/// bkz. [resolveCalorieTone].
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

/// Bir günün kalori tonu.
enum DayCalorieTone {
  /// Bütçenin altında kalınmış.
  under,

  /// Bütçe aşılmış.
  over,

  /// Hedef yok ya da o gün hiç yemek girilmemiş.
  none,
}

/// Bir günün kalori dengesini tona çevirir.
///
/// **Doluluk tonunun yerine geçmiyor, üstüne biniyor:** ikisi ayrı
/// soruları cevaplıyor — "planı yaptım mı" ve "bütçede kaldım mı".
/// Tek tona indirmek, planı eksiksiz yapıp fazla yiyen bir günü ya
/// yeşil ya kırmızı gösterirdi ve ikisi de yanlış olurdu.
///
/// [net] `null` ise o gün **hiç kayıt yok** — sıfır kalori yemiş gibi
/// davranmak, kaydını girmemiş kullanıcıyı "bütçenin altında kaldın"
/// diye ödüllendirmek olurdu.
DayCalorieTone resolveCalorieTone({int? goalKcal, double? net}) {
  if (goalKcal == null || goalKcal <= 0 || net == null) {
    return DayCalorieTone.none;
  }
  return net > goalKcal ? DayCalorieTone.over : DayCalorieTone.under;
}
