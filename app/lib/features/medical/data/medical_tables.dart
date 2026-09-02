import 'package:disport/core/db/sync_columns.dart';
import 'package:drift/drift.dart';

/// Medikal gerçekler (spec v3 §4).
///
/// **Neden tek tablo, dört tür:** kronik durum, kısıt, alerji ve kan
/// grubu aynı yaşam döngüsünü paylaşıyor — kullanıcı yazar, AI belgesi
/// okur, kısıtlar plan doğrulamasına girer. Dört ayrı tablo dört ayrı
/// repository demek olurdu ve hiçbirinin kendine özgü sütunu yok.
@DataClassName('MedicalFactRow')
class MedicalFacts extends Table with SyncColumns {
  /// `MedicalFactKind` enum adı: condition | restriction | allergy |
  /// bloodType.
  TextColumn get kind => text()();

  /// Kullanıcıya görünen metin — serbest ("İnsülin direnci").
  TextColumn get label => text()();

  /// Serbest ek ("derin çömelme yok").
  TextColumn get note => text().nullable()();

  /// Öneri çipinden seçildiyse makine kimliği (`insulinResistance`…).
  ///
  /// Check-up motoru **yalnız** kimlikli kayıtları koşullarda kullanır —
  /// serbest metni yorumlamaya kalkmak "IR" yazan kullanıcıda sessizce
  /// yanlış sonuç üretirdi. Serbest eklenen kayıtta boş.
  TextColumn get conditionId => text().nullable()();

  /// Gerçeğin tarihi, `yyyy-MM-dd` (v3.1 §7). Bugün yalnız teşhiste
  /// anlamlı; sütun genel — ameliyat tarihi gibi ileriye açık.
  TextColumn get factDate => text().nullable()();
}

/// Öğün davranışları (spec v3 §3.4).
///
/// Günlük Düzen'in parçası: her öğünün saati ve planlanma biçimi.
/// "Ben işçiyim, yemekhanede ne varsa onu yiyorum" gerçeği plan
/// isteğine girmezse AI öğle yemeği önermeye devam eder ve plan ilk
/// günden yalan söyler.
@DataClassName('MealBehaviorRow')
class MealBehaviors extends Table with SyncColumns {
  /// `MealKind` enum adı — öğün başına en fazla bir satır.
  TextColumn get mealKind => text()();

  /// `HH:mm`; boşsa saat esnek.
  TextColumn get time => text().nullable()();

  /// `MealBehavior` enum adı: planned | fixed | external.
  TextColumn get behavior => text().withDefault(const Constant('planned'))();

  /// `fixed`: ne yendiğinin serbest tarifi ("menemen + çay").
  TextColumn get fixedNote => text().nullable()();

  /// `fixed`: tarif besinlere bağlandıysa
  /// `[{foodId, quantity, portionId?}]`. Bağ varsa "Her zamanki"
  /// düğmesi kalemleri snapshot'la kayda çevirir; yoksa düğme
  /// görünmez — kalorisiz kayıt yazılmaz.
  TextColumn get fixedItemsJson => text().nullable()();
}

/// Sevilen sporlar (spec v3 §3.3).
///
/// `activities` tablosuna referans + isteğe bağlı sıklık notu. AI
/// belgesine "sevdiği sporlar" bölümü olarak gider — plan basketbolu
/// pazar sabahına koyabilsin.
@DataClassName('FavoriteSportRow')
class FavoriteSports extends Table with SyncColumns {
  TextColumn get activityId => text()();

  /// "Haftada 1 · pazar sabahı" — kullanıcının kendi metni.
  TextColumn get note => text().nullable()();
}
