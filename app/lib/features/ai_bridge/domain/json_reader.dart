/// Ayrıştırma hatası — hangi alanın nesi yanlış.
class JsonFieldError implements Exception {
  const JsonFieldError(this.path, this.problem);

  /// `days[2].exercises[0].exerciseId` gibi tam yol.
  final String path;

  /// Türkçe açıklama: "eksik", "sayı olmalı"…
  final String problem;

  @override
  String toString() => '`$path` $problem';
}

/// Alan yolunu izleyen JSON okuyucu.
///
/// Neden elle yazıldı: bu ayrıştırıcının hata mesajları kullanıcı
/// tarafından **AI'a geri yapıştırılıyor** (spec 7.3). Hazır bir kod
/// üreteci bozuk girdide "type 'Null' is not a subtype of type 'String'"
/// der; hangi günün hangi alanının eksik olduğunu söylemez. AI o mesajla
/// neyi düzelteceğini bilemez ve döngü tıkanır.
///
/// Bu okuyucu her erişimde yolu biriktirir, böylece hata
/// "`days[2].exercises[0].exerciseId` eksik" diye çıkar.
class JsonReader {
  const JsonReader(this._value, [this._path = '']);

  factory JsonReader.root(Object? value) => JsonReader(value);

  final Object? _value;
  final String _path;

  String get path => _path.isEmpty ? '(kök)' : _path;

  Never _fail(String problem) => throw JsonFieldError(path, problem);

  /// Nesne alanına iner. Alan yoksa okuyucu "yok" durumunda döner;
  /// hata ancak zorunlu bir tip istendiğinde atılır.
  JsonReader operator [](String key) {
    final map = _value;
    if (map == null) return JsonReader(null, _child(key));
    if (map is! Map<String, dynamic>) _fail('nesne olmalı');
    return JsonReader(map[key], _child(key));
  }

  String _child(String key) => _path.isEmpty ? key : '$_path.$key';

  bool get exists => _value != null;

  Map<String, dynamic> get asMap {
    final value = _value;
    if (value == null) _fail('eksik');
    if (value is! Map<String, dynamic>) _fail('nesne olmalı');
    return value;
  }

  /// Dizi elemanlarını okuyucu olarak verir; her biri kendi yolunu taşır.
  List<JsonReader> get asList {
    final value = _value;
    if (value == null) _fail('eksik');
    if (value is! List) _fail('dizi olmalı');
    return [
      for (final (index, item) in value.indexed)
        JsonReader(item, '$_path[$index]'),
    ];
  }

  List<JsonReader> listOrEmpty() => exists ? asList : const [];

  String get asString {
    final value = _value;
    if (value == null) _fail('eksik');
    if (value is! String) _fail('metin olmalı');
    if (value.trim().isEmpty) _fail('boş olamaz');
    return value;
  }

  String? get asStringOrNull {
    if (!exists) return null;
    final value = _value;
    if (value is! String) _fail('metin olmalı');
    return value.trim().isEmpty ? null : value;
  }

  String stringOr(String fallback) => asStringOrNull ?? fallback;

  int get asInt {
    final value = _value;
    if (value == null) _fail('eksik');
    if (value is int) return value;
    // AI bazen tam sayıyı 3.0 diye yazıyor; kayıpsızsa kabul et.
    if (value is double && value == value.roundToDouble()) {
      return value.toInt();
    }
    _fail('tam sayı olmalı');
  }

  int? get asIntOrNull => exists ? asInt : null;

  double get asDouble {
    final value = _value;
    if (value == null) _fail('eksik');
    if (value is num) return value.toDouble();
    _fail('sayı olmalı');
  }

  bool boolOr(bool fallback) {
    if (!exists) return fallback;
    final value = _value;
    if (value is! bool) _fail('doğru/yanlış olmalı');
    return value;
  }

  List<String> get asStringList => [for (final item in asList) item.asString];

  List<String> stringListOrEmpty() =>
      exists ? asStringList : const <String>[];

  /// Değeri izin verilen kümede olan bir metin. Değilse seçenekleri
  /// listeleyen hata verir — AI düzeltmeyi böyle yapabiliyor.
  String enumValue(Set<String> allowed) {
    final value = asString;
    if (!allowed.contains(value)) {
      _fail('geçersiz: "$value". Beklenen: ${allowed.join(" | ")}');
    }
    return value;
  }
}
