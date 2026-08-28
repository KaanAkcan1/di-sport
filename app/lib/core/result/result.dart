/// Hata yönetimi için taşıyıcı tip. Exception fırlatmak yerine
/// başarı/başarısızlık açıkça döndürülür (spec Bölüm 10).
///
/// `sealed` olması derleyicinin `switch` içinde tüm durumların
/// karşılandığını denetlemesini sağlar: yeni bir durum eklenirse
/// eksik kalan her `switch` derleme hatası verir.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}

final class Failure {
  const Failure({required this.message, this.cause});

  /// Kullanıcıya gösterilebilir, gerekirse AI'a geri yapıştırılabilir metin.
  final String message;

  /// Özgün hata nesnesi (varsa) — günlüğe yazmak için.
  final Object? cause;

  @override
  String toString() => 'Failure($message)';
}
