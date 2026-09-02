import 'package:disport/core/db/sync_columns.dart';
import 'package:drift/drift.dart';

/// Bir antrenman seansının başı ve sonu.
///
/// **Neden ayrı tablo:** `exercise_logs` yalnız set satırları tutuyor
/// ve setlerin toplam süresi seansın süresi değil — aradaki dinlenme,
/// ısınma ve hazırlık da harcama üretiyor. Kuvvet antrenmanının
/// kalorisi seans süresinden hesaplanıyor (spec §5.5); seans kaydı
/// yoksa **kcal üretilmiyor**, tahmin uydurulmuyor.
@DataClassName('WorkoutSessionRow')
class WorkoutSessions extends Table with SyncColumns {
  /// `yyyy-MM-dd`.
  TextColumn get date => text()();

  DateTimeColumn get startedAt => dateTime()();

  /// Açık seans — uygulama kapanmış ya da antrenman bitirilmemiş.
  DateTimeColumn get endedAt => dateTime().nullable()();

  /// Seans sonu zorlanma, 1-10 (Borg CR10 yaklaşımı; v3.1 §6).
  /// İsteğe bağlı — kapatılırsa null kalır.
  IntColumn get rpe => integer().nullable()();

  /// "Hangi hareket rahatsız etti" serbest notu. AI belgesinin yük
  /// ilerletme bölümüne gider.
  TextColumn get painNote => text().withDefault(const Constant(''))();
}
