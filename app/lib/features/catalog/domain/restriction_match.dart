import 'package:disport/core/utils/turkish_text.dart';
import 'package:disport/features/catalog/domain/exercise.dart';

/// Hareket kısıtı eşleşmesi (v3 §6.5) — saf.
///
/// Yalnız **kimlikli** kısıtlar eşleştirilir (`medical_facts.conditionId`);
/// serbest metni yorumlamaya kalkmak "dizim ağrıyor ama squat iyi
/// geliyor" yazan kullanıcıda sessizce yanlış uyarı üretirdi.
/// Eşleşen hareketin güvenlik satırı amber vurgulanır; hareket
/// **engellenmez** — uyarı hatırlatır, karar kullanıcının.
const _restrictionKeywords = <String, List<String>>{
  'kneeIssue': ['diz', 'knee', 'squat', 'lunge', 'quadriceps'],
  'backIssue': ['bel', 'sirt', 'back', 'deadlift', 'lower back'],
  'shoulderIssue': ['omuz', 'shoulder', 'overhead', 'delts'],
};

/// Hareket verilen kısıt kimliğiyle eşleşiyor mu.
///
/// Bakılan alanlar: güvenlik metinleri (iki dil), kas grupları ve
/// İngilizce ad. Katlama Türkçe kurallarıyla — "DİZ" ile "diz" aynı.
bool exerciseMatchesRestriction(Exercise exercise, String conditionId) {
  final keywords = _restrictionKeywords[conditionId];
  if (keywords == null) return false;

  final haystack = TurkishText.fold(
    [
      exercise.safety ?? '',
      exercise.safetyEn ?? '',
      exercise.nameEn,
      ...exercise.primaryMuscles,
      ...exercise.secondaryMuscles,
    ].join(' '),
  );

  return keywords.any((keyword) => haystack.contains(TurkishText.fold(keyword)));
}

/// Kullanıcının kısıt kimliklerinden hareketle eşleşenler.
List<String> matchingRestrictions(
  Exercise exercise,
  Iterable<String> conditionIds,
) => [
  for (final id in conditionIds)
    if (exerciseMatchesRestriction(exercise, id)) id,
];
