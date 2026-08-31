/// Türkçe metin için arama yardımcıları.
abstract final class TurkishText {
  /// Türkçe harfleri ASCII karşılıklarına indirger ve küçültür.
  ///
  /// İki ayrı sorunu birden çözer:
  ///
  /// **1. SQLite `lower()` yalnız ASCII'yi küçültür.** "Şınav" kaydı
  /// veritabanında büyük Ş ile durur; `lower()` ona dokunmaz ve
  /// "şınav" araması boş döner.
  ///
  /// **2. Dart'ın `toLowerCase()`'i Türkçe'yi bilmez.** `'I'` harfini
  /// noktalı `'i'`ye çevirir; oysa Türkçede karşılığı noktasız `'ı'`dır.
  /// Bu yüzden "ŞINAV".toLowerCase() = "şinav", kayıttaki "Şınav" ise
  /// "şınav" olur ve yine eşleşmezler.
  ///
  /// Katlama ayrıca aksan duyarsız arama kazandırır: kullanıcı klavye
  /// düzeniyle uğraşmadan "sinav", "sınav" ya da "Şınav" yazabilir,
  /// üçü de aynı kaydı bulur. Türkçede bu bir kolaylık değil beklentidir.
  ///
  /// Kayıt yazılırken ve arama yapılırken **aynı** işlevden geçirilmesi
  /// şart; tek tarafta uygulanırsa eşleşme yine tutmaz.
  static String fold(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      buffer.write(_foldChar(String.fromCharCode(rune)));
    }
    return buffer.toString();
  }

  static String _foldChar(String ch) => switch (ch) {
    'ı' || 'İ' || 'I' || 'i' || 'î' || 'Î' => 'i',
    'ş' || 'Ş' => 's',
    'ğ' || 'Ğ' => 'g',
    'ü' || 'Ü' || 'û' || 'Û' => 'u',
    'ö' || 'Ö' => 'o',
    'ç' || 'Ç' => 'c',
    'â' || 'Â' => 'a',
    _ => ch.toLowerCase(),
  };
}
