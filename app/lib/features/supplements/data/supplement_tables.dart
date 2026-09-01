import 'package:disport/core/db/sync_columns.dart';
import 'package:drift/drift.dart';

/// Takviye ve ilaç tanımı (spec §7).
///
/// **Plan slotu değil ayrı tablo:** takviye her gün tekrar eder ve
/// plandan bağımsız yaşar. Plan slotu olsaydı yeni bir plan içeri
/// alındığında kullanıcının D vitamini hatırlatması sessizce kaybolurdu.
///
/// **Ad tek alan, `nameTr`/`nameEn` değil:** takviye adı kullanıcının
/// kendi metni. Kimsenin vitamini uygulamanın çevirmesi gereken bir şey
/// değil (spec §3.1 kullanıcı metni kuralı).
@DataClassName('SupplementRow')
class Supplements extends Table with SyncColumns {
  TextColumn get name => text()();

  /// "1000", "2", "1/2" — serbest metin.
  ///
  /// Sayı değil: kullanıcı "yarım tablet" yazabilmeli ve doz biçimi
  /// ilaçtan ilaca değişiyor.
  TextColumn get dose => text().withDefault(const Constant(''))();

  /// "IU", "tablet", "mg", "damla".
  TextColumn get unit => text().withDefault(const Constant(''))();

  /// `["08:00","21:30"]` — gün içindeki alım saatleri, sıralı.
  TextColumn get timesJson => text().withDefault(const Constant('[]'))();

  /// `[1,3,5]` ISO hafta günü (1=Pazartesi). **Boş dizi = her gün.**
  TextColumn get weekdaysJson => text().withDefault(const Constant('[]'))();

  TextColumn get note => text().withDefault(const Constant(''))();
}

/// Bir takviyenin belirli bir gün ve saatteki alım kaydı.
///
/// Satır yalnız kullanıcı işaretlediğinde oluşuyor; "alınmadı" durumu
/// satırın **yokluğu**. Her gün her saat için boş satır üretmek
/// veritabanını gereksiz şişirirdi.
@DataClassName('SupplementLogRow')
class SupplementLogs extends Table with SyncColumns {
  TextColumn get supplementId => text()();

  /// `yyyy-MM-dd`.
  TextColumn get date => text()();

  /// Planlanan saat, `HH:mm`. Aynı gün iki farklı saatte alınan
  /// takviyenin iki ayrı kaydı olur.
  TextColumn get time => text()();

  /// Fiilen işaretlendiği an. `null` ise işaret kaldırılmış —
  /// satır duruyor ama alınmamış sayılıyor (yanlış dokunuş geri alındı).
  DateTimeColumn get takenAt => dateTime().nullable()();
}
