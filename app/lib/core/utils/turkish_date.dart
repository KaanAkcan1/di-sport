/// Türkçe tarih biçimleri.
///
/// `intl` paketi eklenmedi: uygulama tek dilli ve çevrimdışı, ihtiyaç
/// duyulan tek şey ay adları. `intl`'in yerelleştirme verisi uygulama
/// boyutuna megabaytlar ekler, karşılığında burada kullanılmayan
/// yüzlerce yerel ayar getirir.
abstract final class TurkishDate {
  static const months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  /// Kısa ay adları — dar satırlar için.
  static const monthsShort = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];

  /// `3 Eylül`
  static String dayMonth(DateTime date) =>
      '${date.day} ${months[date.month - 1]}';

  /// `3 Eyl 2026` — yıl gerektiğinde; tahlil geçmişi yıllara yayılır.
  static String dayMonthYear(DateTime date) =>
      '${date.day} ${monthsShort[date.month - 1]} ${date.year}';

  /// ISO metinden; ayrıştırılamazsa metnin kendisi döner.
  ///
  /// Bozuk bir tarih yüzünden ekran çökmemeli; kullanıcı ham değeri
  /// görüp düzeltebilir.
  static String isoToDayMonthYear(String iso) {
    final date = DateTime.tryParse(iso);
    return date == null ? iso : dayMonthYear(date);
  }
}
