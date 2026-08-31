import 'dart:convert';

import 'package:disport/core/db/app_database.dart';
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

  /// Tohum verisini yükler. Tablo doluysa hiçbir şey yapmaz.
  ///
  /// Uygulama her açılışta çağırır; ikinci çağrının ucuz ve etkisiz
  /// olması gerekiyor. Kullanıcının eklediği hareketlerin üzerine
  /// yazmaması da bu kontrole bağlı.
  Future<void> seedFromJson(String jsonString) async {
    if (await countAll() > 0) return;

    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final items = (decoded['exercises'] as List)
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();

    await _db.batch((batch) {
      batch.insertAll(_db.exercises, [for (final e in items) _toRow(e)]);
    });
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
    nameTr: e.nameTr,
    nameEn: e.nameEn,
    category: e.category.name,
    location: e.location.name,
    difficulty: e.difficulty,
    isUserDefined: Value(e.isUserDefined),
    searchText: TurkishText.fold(
      [e.nameTr, e.nameEn, ...e.primaryMuscles, ...e.secondaryMuscles].join(' '),
    ),
    equipmentJson: jsonEncode(e.equipment),
    primaryMusclesJson: jsonEncode(e.primaryMuscles),
    detailJson: jsonEncode(e.toJson()),
  );

  Exercise _fromRow(ExerciseRow row) =>
      Exercise.fromJson(jsonDecode(row.detailJson) as Map<String, dynamic>);
}
