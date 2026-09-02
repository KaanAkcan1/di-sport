/// Ekipman ekranının "Etkisi" hesapları — saf (v3 §3.3).
///
/// Ekran iki soru soruyor: "bu işaretlerle kaç hareket yapabilirim" ve
/// "şu ekipmanı işaretlersem kaç hareket **açılır**". İkisi de katalog
/// listesi + işaret kümesiyle cevaplanıyor; veritabanı ya da widget
/// gerekmiyor, testi emülatörsüz koşuyor.
library;

import 'package:disport/features/catalog/domain/equipment_kind.dart';
import 'package:disport/features/catalog/domain/exercise.dart';

/// Konum süzgeci: ev sekmesi `home` ve `both` hareketlerine, salon
/// sekmesi `gym` ve `both` hareketlerine bakar.
bool _atLocation(Exercise exercise, ExerciseLocation where) =>
    exercise.location == where || exercise.location == ExerciseLocation.both;

bool _doable(Exercise exercise, Set<EquipmentKind> owned) {
  for (final kind in exercise.equipment) {
    if (!kind.needsInventory) continue;
    if (!owned.contains(kind)) return false;
  }
  return true;
}

/// Mevcut işaretlerle yapılabilen hareket sayısı.
int doableCount(
  List<Exercise> catalog,
  Set<EquipmentKind> owned,
  ExerciseLocation where,
) => catalog
    .where((e) => _atLocation(e, where) && _doable(e, owned))
    .length;

/// [candidate] işaretlenirse **ek olarak** açılacak hareket sayısı.
///
/// Zaten yapılabilenler sayılmaz — "5 hareket açar" yazan satır
/// işaretlenince sayının gerçekten 5 artması gerekir, yoksa etiket
/// güven kaybettirir.
int unlockCount(
  List<Exercise> catalog,
  Set<EquipmentKind> owned,
  ExerciseLocation where,
  EquipmentKind candidate,
) {
  if (owned.contains(candidate)) return 0;
  final withCandidate = {...owned, candidate};
  var count = 0;
  for (final exercise in catalog) {
    if (!_atLocation(exercise, where)) continue;
    if (_doable(exercise, owned)) continue;
    if (_doable(exercise, withCandidate)) count++;
  }
  return count;
}
