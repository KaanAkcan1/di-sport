import 'package:disport/core/utils/turkish_text.dart';
import 'package:flutter/widgets.dart' show Locale;

/// Dile bağlı metin işlemleri.
///
/// [TurkishText] Türkçeyi varsayıyor; uygulama iki dilli olunca bu bir
/// hata kaynağı oldu. Bu sınıf kararı locale'e devrediyor ve Türkçe
/// yolunda mevcut kodu çağırıyor — kural tek yerde kalıyor, ikizlenmiyor.
abstract final class LocaleText {
  /// Büyük harfe çevirir.
  ///
  /// Türkçede `i`nin büyüğü `İ`, `ı`nın büyüğü `I`; Dart'ın ASCII
  /// kuralı "Kilo"yu "KILO" yapıyor ve bu Türkçede "kılo" okunur.
  /// İngilizcede ise `i` → `I` doğru olan.
  static String upper(Locale locale, String input) =>
      _isTurkish(locale) ? TurkishText.upper(input) : input.toUpperCase();

  /// Arama katlaması — aksan, büyük/küçük harf ve ayraç duyarsız.
  ///
  /// Türkçe yolu diakritikleri indirger (`ş`→`s`, `ı`/`İ`→`i`);
  /// İngilizce yolu yalnız küçültür. İki dilin katlaması **farklı**
  /// sonuç veriyor: "Şınav" TR'de "sinav", EN'de "şınav".
  ///
  /// İkisinde de **ayraçlar atılır**: hareket adlarının yarısı tireli
  /// ("Push-Up", "Sit-Up", "E-Z Bar") ve kimse arama kutusuna tire
  /// yazmıyor. Boşluk korunuyor — sözcük sınırı bilgi taşıyor.
  static String fold(Locale locale, String input) {
    final folded = _isTurkish(locale)
        ? TurkishText.fold(input)
        : input.toLowerCase();
    return folded.replaceAll(_separators, '');
  }

  /// Tire, nokta, kesme, eğik çizgi — ad içinde geçen ama aranırken
  /// yazılmayan işaretler.
  static final _separators = RegExp(r"[-–—._/'’`()]");

  /// Sorgu, metnin **herhangi bir dildeki** katlamasıyla eşleşiyor mu.
  ///
  /// **Neden gerekli:** katalogda hareketin iki adı var — "Push-Up" ve
  /// "Şınav". Türkçe arayüzdeki kullanıcı "pushup" yazabilir, İngilizce
  /// arayüzdekiyse "sinav". Tek bir katlamaya bağlanmak birini
  /// cezalandırırdı.
  ///
  /// **Nerede kullanılır:** yalnız **bellek içi** listelerde (besin
  /// arama, M9). Katalog araması veritabanındaki katlanmış `searchText`
  /// sütunu üzerinde LIKE ile çalışıyor; orada çözüm sorgu tarafında
  /// değil **yazım** tarafında — blob her iki katlamayı da taşıyor
  /// (bkz. `CatalogRepository.searchText`).
  static bool matchesAnyLocale(String query, String haystack) {
    final needle = query.trim();
    if (needle.isEmpty) return true;

    const tr = Locale('tr');
    const en = Locale('en');

    return fold(tr, haystack).contains(fold(tr, needle)) ||
        fold(en, haystack).contains(fold(en, needle));
  }

  static bool _isTurkish(Locale locale) => locale.languageCode == 'tr';
}
