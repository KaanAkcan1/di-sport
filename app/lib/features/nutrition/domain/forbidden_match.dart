import 'package:disport/core/utils/turkish_text.dart';
import 'package:disport/features/nutrition/domain/food.dart';

/// Bir besin yasaklı listesine takılıyor mu (v3 §5.4) — saf.
///
/// İki eşleşme yolu: yasaklı satıra bağlanmış besin id'leri (kesin) ve
/// etiket metninin besin adında çift dilli katlamayla geçmesi (yaklaşık;
/// "hamur işi" lahmacunu yakalamaz — kabul edilmiş sınır, eşleşme ancak
/// ad düzeyinde). Kayıt **engellenmez**; rozet yalnız hatırlatır.
bool isForbiddenFood({
  required Food food,
  required List<String> labels,
  Map<String, List<String>> foodIds = const {},
}) {
  final haystack = TurkishText.fold('${food.nameTr ?? ''} ${food.nameEn}');

  for (final label in labels) {
    if (foodIds[label]?.contains(food.id) ?? false) return true;

    final needle = TurkishText.fold(label.trim());
    if (needle.isEmpty) continue;
    if (haystack.contains(needle)) return true;
  }
  return false;
}
