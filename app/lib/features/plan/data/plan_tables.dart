import 'package:disport/core/db/sync_columns.dart';
import 'package:drift/drift.dart';

/// 28 günlük program (spec 5.2).
///
/// Tarihler `yyyy-MM-dd`, saatler `HH:mm` metin olarak tutulur: sıralama
/// sözlük sırasıyla aynı, saat dilimi taşımıyorlar ve SQLite'ta tarih
/// tipi zaten yok.
@DataClassName('PlanRow')
class Plans extends Table with SyncColumns {
  TextColumn get title => text()();
  TextColumn get startDate => text()();
  TextColumn get endDate => text()();
  IntColumn get weeks => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  TextColumn get goalsJson => text()();
  TextColumn get rulesJson => text()();

  /// AI'ın verdiği ham belge; elle kurulan planlarda boş.
  TextColumn get sourceRaw => text().withDefault(const Constant(''))();

  IntColumn get planSchemaVersion => integer().withDefault(const Constant(1))();
}

@DataClassName('PlanDayRow')
class PlanDays extends Table with SyncColumns {
  TextColumn get planId => text().references(Plans, #id)();
  TextColumn get date => text()();
  TextColumn get type => text()();
  IntColumn get weekIndex => integer()();
  TextColumn get headline => text().withDefault(const Constant(''))();
  TextColumn get dinnerSuggestion => text().withDefault(const Constant(''))();
}

@DataClassName('PlanSlotRow')
class PlanSlots extends Table with SyncColumns {
  TextColumn get planDayId => text().references(PlanDays, #id)();
  TextColumn get time => text()();
  TextColumn get kind => text()();

  /// `MealKind` enum adı — yalnız `kind == meal` slotlarında dolu.
  ///
  /// **Neden ayrı sütun:** öğün türü bir kimlik, etiket ise kullanıcının
  /// metni ("Kahvaltı" ya da "Sabah yemeği" yazabilir). `label`dan
  /// çıkarmaya çalışmak, dil değişince ya da kullanıcı etiketi
  /// değiştirince sessizce kopardı.
  TextColumn get mealKind => text().nullable()();

  TextColumn get label => text()();
  TextColumn get note => text().nullable()();
  IntColumn get orderIndex => integer()();
}

@DataClassName('PlanExerciseRow')
class PlanExercises extends Table with SyncColumns {
  TextColumn get planDayId => text().references(PlanDays, #id)();

  /// Katalogdaki hareketin id'si. Yabancı anahtar kısıtı bilinçli olarak
  /// konmadı: katalogdan bir hareket kalkarsa (soft delete) geçmiş plan
  /// yine de okunabilir kalmalı.
  TextColumn get exerciseId => text()();

  IntColumn get orderIndex => integer()();
  IntColumn get sets => integer().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get durationSec => integer().nullable()();
  IntColumn get restSec => integer().nullable()();
  /// Serbest metin — "orta tempo", "RPE 7". **Ayrıştırılmıyor:**
  /// AI'ın ve kullanıcının yazdığı her şeyi bir sayıya çevirmeye
  /// çalışmak sessizce yanlış kalori üretirdi.
  TextColumn get intensity => text().nullable()();

  // Kardiyo şiddeti — kalori hesabının girdisi (spec §5.5). Serbest
  // `intensity` metninden ayrı üç tipli alan: hesap yapılabilir bir
  // sayı ile insana yazılmış bir not aynı sütunda duramaz.
  RealColumn get speedKmh => real().nullable()();
  RealColumn get gradePct => real().nullable()();

  /// `Effort` enum adı — bisiklette hız/eğim yerine efor seviyesi.
  TextColumn get effort => text().nullable()();

  TextColumn get note => text().nullable()();
}
