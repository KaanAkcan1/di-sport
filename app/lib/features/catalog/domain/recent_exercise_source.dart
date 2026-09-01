/// Katalogda "son yaptıkların" bölümünü besleyen kayıt.
class RecentExercise {
  const RecentExercise({
    required this.exerciseId,
    required this.date,
    required this.summary,
    this.progressLabel,
  });

  final String exerciseId;

  /// `yyyy-MM-dd` — son çalışıldığı gün.
  final String date;

  /// "3×12 · 12,5 kg" — son seansın tek satırlık özeti.
  final String summary;

  /// "↗ +2,5 kg" gibi ilerleme etiketi; yoksa null.
  ///
  /// Bir öncekiyle kıyas yoksa (ilk kez yapılmışsa) etiket hiç
  /// çizilmiyor — "+0" yazmak ilerleme yokmuş gibi okunur, oysa
  /// karşılaştıracak bir şey yok.
  final String? progressLabel;
}

/// Katalog feature'ının antrenman geçmişine bakma kapısı.
///
/// **Neden port:** kayıtlar `workout` feature'ının `data` katmanında.
/// Katalog oradan doğrudan okusaydı iki feature birbirine kenetlenirdi.
/// `ai_bridge`'de kurulan desenin aynısı: **tüketen** taraf arayüzü
/// tanımlar, üreten taraf uygular, bağlama `app` katmanında yapılır.
abstract interface class RecentExerciseSource {
  /// En son çalışılan hareketler, yeniden eskiye.
  Stream<List<RecentExercise>> watchRecent({int limit = 5});
}
