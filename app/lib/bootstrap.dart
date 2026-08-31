import 'dart:async';

import 'package:disport/app/app.dart';
import 'package:disport/features/catalog/data/catalog_repository.dart';
import 'package:disport/features/reminders/application/reminder_providers.dart';
import 'package:disport/features/today/data/daily_rules_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Uygulamanın gerçek giriş noktası.
///
/// `main.dart` yerine ayrı bir dosyada durmasının nedeni: açılışta
/// yapılması gereken işler burada toplanır ve `main` tek satır kalır.
/// M5'te alarm penceresinin kaydırılması da buraya girecek.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Riverpod kapsayıcısı elle kuruluyor: arayüz çizilmeden önce
  // veritabanına erişmek gerekiyor. `runApp`tan sonra tohumlamak,
  // ilk karede boş bir katalog göstermek demek olurdu.
  final container = ProviderContainer();

  await _seedCatalog(container);
  await _seedDailyRules(container);

  // Bildirim penceresi arka planda kaydırılıyor: kurulumu beklemek ilk
  // kareyi geciktirir ve kullanıcı uygulamayı açtığında alarm kurmak
  // için bir sebep yok, alarm ileride çalacak.
  unawaited(_rescheduleReminders(container));

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DisportApp(),
    ),
  );
}

/// Egzersiz kataloğunu ilk açılışta veritabanına alır.
///
/// Her açılışta çağrılır ama tablo doluysa hiçbir şey yapmaz; kullanıcının
/// eklediği hareketlerin üzerine yazma riski yok.
///
/// Hata durumunda uygulama yine de açılır: katalog boş kalır, kullanıcı
/// bir sonraki açılışta tekrar dener. Tohumlama hatası uygulamayı
/// başlatılamaz hâle getirmemeli.
Future<void> _seedCatalog(ProviderContainer container) async {
  try {
    final json = await rootBundle.loadString('assets/catalog.json');
    await CatalogRepository(
      container.read(appDatabaseProvider),
    ).seedFromJson(json);
  } catch (error, stackTrace) {
    debugPrint('Katalog tohumlaması başarısız: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

/// Kâğıt çizelgenin üç kuralını ilk açılışta ekler.
///
/// Katalog tohumlamasıyla aynı mantık: her açılışta çağrılır, zaten
/// varsa hiçbir şey yapmaz. Kullanıcının sildiği kuralı da geri
/// getirmez — bkz. `DailyRulesRepository.seedBuiltIns`.
Future<void> _seedDailyRules(ProviderContainer container) async {
  try {
    await DailyRulesRepository(
      container.read(appDatabaseProvider),
    ).seedBuiltIns();
  } catch (error, stackTrace) {
    debugPrint('Kural tohumlaması başarısız: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

/// Bildirim penceresini kaydırır.
///
/// Her açılışta çağrılıyor: pencere yalnız yedi gün ileriyi kapsıyor,
/// uygulama bir hafta açılmazsa alarmlar kendiliğinden tükenir. Bu
/// kabul edilmiş bir sınır — bir hafta açılmamış bir takip
/// uygulamasının alarm çalması zaten kullanıcıyı geri getirmiyor.
///
/// Hata yutuluyor: bildirim izni reddedilmiş ya da platform kanalı
/// hazır değilse uygulama yine açılmalı.
Future<void> _rescheduleReminders(ProviderContainer container) =>
    rescheduleQuietly(container.read(reminderSchedulerProvider));
