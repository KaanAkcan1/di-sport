import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:disport/core/db/app_database.dart';
import 'package:disport/core/utils/locale_text.dart';
import 'package:disport/core/utils/turkish_text.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:drift/drift.dart';

/// Katalog verisine erişimin tek kapısı.
///
/// Feature'ın `data/` katmanı: üstündeki `application/` ve
/// `presentation/` katmanları Drift'i hiç görmez (spec 4.4). Faz-2'de
/// bulut senkronu geldiğinde değişecek yer burasıdır; model ve ekranlar
/// aynı kalır.
class CatalogRepository {
  CatalogRepository(this._db);

  final AppDatabase _db;

  Future<int> countAll() async {
    final count = _db.exercises.id.count();
    final query = _db.selectOnly(_db.exercises)..addColumns([count]);
    return (await query.getSingle()).read(count)!;
  }

  /// Tohum verisini yükler ve **güncellenmişse yeniden uygular**.
  ///
  /// **Neden sürüm damgası:** eskiden ölçüt "tablo dolu mu"ydu. Bu,
  /// katalog güncellemesinin mevcut kurulumlara **hiç ulaşmaması**
  /// demekti — yeni hareketler yalnız uygulamayı ilk kez kuranlarda
  /// görünürdü. Kusur M8 gözden geçirmesinde yakalandı.
  ///
  /// Uygulanan sürüm profil tablosunda duruyor. Dosyadaki sürüm daha
  /// büyükse yerleşik kayıtlar **id bazında upsert** ediliyor:
  ///
  /// - Kullanıcının eklediği hareketler (`isUserDefined`) korunuyor.
  /// - Kullanıcının **sildiği** yerleşikler geri gelmiyor — ölçüt
  ///   satırın varlığı (M6 kullanıcı-tanımlı-veri kalıbı 2).
  ///
  /// [readVersion]/[writeVersion] dışarıdan veriliyor: bu depo profil
  /// tablosunu tanımıyor ve tanımaması gerekiyor.
  Future<void> seedFromJson(
    String jsonString, {
    Future<int> Function()? readVersion,
    Future<void> Function(int version)? writeVersion,
  }) async {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final fileVersion = decoded['version'] as int? ?? 1;
    final applied = await readVersion?.call() ?? 0;

    final isEmpty = await countAll() == 0;
    if (!isEmpty && fileVersion <= applied) return;

    final items = (decoded['exercises'] as List)
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();

    if (isEmpty) {
      await _db.batch((batch) {
        batch.insertAll(_db.exercises, [for (final e in items) _toRow(e)]);
      });
    } else {
      // Silinmiş yerleşikler geri gelmesin: yalnız hâlâ duran id'ler
      // güncelleniyor, yenileri ekleniyor.
      final existing = await (_db.select(
        _db.exercises,
      )..where((t) => t.deletedAt.isNull())).get();
      final known = {for (final row in existing) row.id};
      final deleted = await _deletedIds();

      await _db.batch((batch) {
        for (final exercise in items) {
          if (deleted.contains(exercise.id)) continue;
          if (known.contains(exercise.id)) {
            batch.replace(_db.exercises, _toRow(exercise));
          } else {
            batch.insert(_db.exercises, _toRow(exercise));
          }
        }
      });
    }

    await writeVersion?.call(fileVersion);
  }

  Future<Set<String>> _deletedIds() async {
    final rows = await (_db.select(
      _db.exercises,
    )..where((t) => t.deletedAt.isNotNull())).get();
    return {for (final row in rows) row.id};
  }

  /// Filtrelenmiş liste; veritabanı değiştikçe kendiliğinden yenilenir.
  ///
  /// [query] Türkçe ad, İngilizce ad ve hedef kas alanlarında arar —
  /// kullanıcı "karın" yazdığında hareketin adında geçmese de plank'ı
  /// bulmalı.
  Stream<List<Exercise>> watchFiltered({
    String? query,
    ExerciseLocation? location,
    ExerciseCategory? category,
  }) {
    final select = _db.select(_db.exercises)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.nameTr)]);

    if (query != null && query.trim().isNotEmpty) {
      // Aranan metin de kayıtla aynı katlamadan geçer; tek tarafta
      // uygulanırsa Türkçe harfler eşleşmez.
      final needle = '%${TurkishText.fold(query.trim())}%';
      select.where((t) => t.searchText.like(needle));
    }

    if (location != null) {
      // `both` her iki filtrede de görünmeli: evde de salonda da yapılan
      // hareketi filtre dışında bırakmak kullanıcıyı yanıltır.
      select.where(
        (t) =>
            t.location.equals(location.name) |
            t.location.equals(ExerciseLocation.both.name),
      );
    }

    if (category != null) {
      select.where((t) => t.category.equals(category.name));
    }

    return select.watch().map(
      (rows) => [for (final row in rows) _fromRow(row)],
    );
  }

  Future<Exercise?> getById(String id) async {
    final row =
        await (_db.select(_db.exercises)
              ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
            .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Birden çok id'yi tek sorguda getirir — varyant zincirinin adlarını
  /// çözerken kullanılır. Tek tek [getById] çağırmak N+1 sorgu olurdu.
  Future<Map<String, Exercise>> getByIds(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return const {};

    final rows =
        await (_db.select(_db.exercises)
              ..where((t) => t.id.isIn(list) & t.deletedAt.isNull()))
            .get();
    return {for (final row in rows) row.id: _fromRow(row)};
  }

  /// Kullanıcının (M4'te AI önerisiyle) eklediği hareketi kaydeder.
  /// Aynı id varsa üzerine yazar.
  Future<void> upsertUserDefined(Exercise exercise) =>
      _db.into(_db.exercises).insertOnConflictUpdate(_toRow(exercise));

  /// Kaydı silinmiş işaretler. Gerçekten silmez: geçmiş planlar bu
  /// hareketin id'sine referans veriyor olabilir (spec 5, SyncColumns).
  Future<void> softDelete(String id) =>
      (_db.update(_db.exercises)..where((t) => t.id.equals(id))).write(
        ExercisesCompanion(
          deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

  ExercisesCompanion _toRow(Exercise e) => ExercisesCompanion.insert(
    id: e.id,
    updatedAt: DateTime.now().millisecondsSinceEpoch,
    nameTr: e.displayNameTr,
    nameEn: e.nameEn,
    category: e.category.name,
    location: e.location.name,
    difficulty: e.difficulty,
    isUserDefined: Value(e.isUserDefined),
    // Arama blob'u **iki dilin katlamasını da** taşıyor: Türkçe
    // arayüzdeki kullanıcı "pushup", İngilizce arayüzdeki "sinav"
    // yazabilmeli. Tek katlamaya bağlanmak birini cezalandırırdı
    // (M7 düzeltmesi 6). Sorgu tarafı tek katlama uyguluyor ve
    // ikisinden biri tutuyor.
    searchText: [
      LocaleText.fold(
        const Locale('tr'),
        [
          e.displayNameTr,
          e.nameEn,
          ...e.primaryMuscles,
          ...e.secondaryMuscles,
        ].join(' '),
      ),
      LocaleText.fold(
        const Locale('en'),
        [e.displayNameTr, e.nameEn].join(' '),
      ),
    ].join(' '),
    equipmentJson: jsonEncode([for (final kind in e.equipment) kind.name]),
    primaryMusclesJson: jsonEncode(e.primaryMuscles),
    detailJson: jsonEncode(e.toJson()),
  );

  Exercise _fromRow(ExerciseRow row) =>
      Exercise.fromJson(jsonDecode(row.detailJson) as Map<String, dynamic>);
}
