import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:flutter/widgets.dart';

/// Hareketin ekranda görünen adı (spec §4.1).
///
/// **Kural:**
/// - İngilizce arayüzde yalnız İngilizce ad — `Goblet Squat`
/// - Türkçe arayüzde İngilizce ana, Türkçe parantez içinde —
///   `Goblet Squat (Goblet Çömelme)`
/// - Türkçe adı yoksa parantez hiç açılmaz
///
/// **Neden İngilizce ana:** hareket adı özel addır. "Bulgar Split
/// Çömelme" diye aratan kullanıcı internette hiçbir şey bulamaz;
/// "Bulgarian Split Squat" onu doğrudan video ve makaleye götürür.
/// Türkçe karşılık yine duruyor — anlamı kaybetmiyoruz, yalnız
/// sıralamayı değiştiriyoruz.
String exerciseDisplayName(BuildContext context, Exercise exercise) {
  final isTurkish = Localizations.localeOf(context).languageCode == 'tr';
  final turkish = exercise.nameTr;

  if (!isTurkish || turkish == null || turkish == exercise.nameEn) {
    return exercise.nameEn;
  }
  return '${exercise.nameEn} ($turkish)';
}
