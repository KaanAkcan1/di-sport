import 'package:disport/features/reminders/domain/reminder_planner.dart';

/// Platform bildirim katmanının sözleşmesi.
///
/// `core`'da duruyor ama `reminders/domain`'den tip alıyor — bu, "core
/// feature import etmez" kuralının bilinçli tek istisnası **değil**:
/// [PendingReminder] saf bir veri tipi ve zamanlama mantığının sahibi
/// `reminders`. Alternatif, aynı tipi `core`'da ikinci kez tanımlamaktı;
/// iki kopyanın birbirinden kayması, tek yönlü bir import okundan daha
/// pahalı.
///
/// Arayüz olmasının nedeni test edilebilirlik: zamanlayıcı gerçek
/// platform çağrısı yapmadan sınanabiliyor.
abstract interface class NotificationService {
  /// Bildirim izni ister. Kullanıcı reddederse `false`.
  Future<bool> requestPermissions();

  /// Tam zamanlı alarm kurulabiliyor mu — **sormadan** bakar.
  ///
  /// Kullanıcıya hiçbir şey göstermez. Ayrım önemli: Android'de tam
  /// alarm iznini *istemek* diyalog açmaz, kullanıcıyı doğrudan sistem
  /// ayarları sayfasına atar. Bunu bildirim kurarken yapmak,
  /// uygulamayı açan kullanıcıyı sebepsiz yere ayarlara fırlatmak
  /// olurdu.
  Future<bool> canScheduleExact();

  /// Tam zamanlı alarm iznini ister — sistem ayarları sayfasını açar.
  ///
  /// Yalnız kullanıcı bunu açıkça istediğinde çağrılmalı (Ayarlar
  /// ekranındaki satır). Reddedilirse bildirimler yine kurulur, yalnız
  /// Doze kipinde birkaç dakika gecikebilir — 06:30 tartı hatırlatması
  /// 06:34'te de işini görür, sessizce hiç kurmamaktan iyidir.
  Future<bool> requestExactPermission();

  /// Bekleyen tüm bildirimleri iptal edip verilen listeyi kurar.
  ///
  /// Tek yöntem olması kasıtlı: kaydırmalı pencere her açılışta baştan
  /// hesaplanıyor, "hangisi zaten kuruluydu" defterini tutmak iki
  /// kaynağın kayması demekti. Bu hâliyle işlem idempotent — aynı
  /// listeyle iki kez çağırmak bildirimleri ikiye katlamaz.
  Future<void> replaceAll(List<PendingReminder> reminders);

  /// Kurulu bildirim sayısı — ayarlar ekranı bunu gösterir.
  Future<int> pendingCount();
}
