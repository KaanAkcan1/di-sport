import 'dart:async';

import 'package:disport/app/app.dart';
import 'package:disport/app/boot_splash.dart';
import 'package:disport/features/catalog/data/catalog_repository.dart';
import 'package:disport/features/catalog/data/equipment_repository.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/health/data/metric_definitions_repository.dart';
import 'package:disport/features/nutrition/data/activities_repository.dart';
import 'package:disport/features/nutrition/data/nutrition_repository.dart';
import 'package:disport/features/reminders/application/reminder_providers.dart';
import 'package:disport/features/settings/data/profile_repository.dart';
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

  // Tohumlama sürerken donuk yerel splash yerine markanın kendini
  // çizen işareti gösterilir. Gerçek uygulama aşağıdaki ikinci
  // `runApp` ile devralır — Flutter'da runApp'i yeniden çağırmak
  // meşru ve ucuzdur, ağaç yerinde değiştirilir.
  runApp(const BootSplash());

  // Riverpod kapsayıcısı elle kuruluyor: arayüz çizilmeden önce
  // veritabanına erişmek gerekiyor. `runApp`tan sonra tohumlamak,
  // ilk karede boş bir katalog göstermek demek olurdu.
  final container = ProviderContainer();

  // Tohumlama ve açılış animasyonu birlikte beklenir: tohumlama hızlı
  // bitse de işaret çizimini yarıda kesmeyiz (BootSplash.minimumDuration).
  await Future.wait([
    () async {
      await _seedCatalog(container);
      await _seedDailyRules(container);
      await _seedMetricDefinitions(container);
      await _seedEquipment(container);
      await _seedFoods(container);
      await _seedActivities(container);
    }(),
    Future<void>.delayed(BootSplash.minimumDuration),
  ]);

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
const _catalogSeedVersionKey = 'catalog.seededVersion';

Future<void> _seedCatalog(ProviderContainer container) async {
  try {
    final json = await rootBundle.loadString('assets/catalog.json');
    final profile = ProfileRepository(container.read(appDatabaseProvider));

    await CatalogRepository(container.read(appDatabaseProvider)).seedFromJson(
      json,
      // Uygulanan tohum sürümü profil tablosunda; katalog deposu o
      // tabloyu tanımıyor ve tanımaması gerekiyor.
      readVersion: () async =>
          int.tryParse(await profile.read(_catalogSeedVersionKey) ?? '') ?? 0,
      writeVersion: (version) =>
          profile.set(_catalogSeedVersionKey, '$version'),
    );
  } catch (error, stackTrace) {
    debugPrint('Katalog tohumlaması başarısız: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

/// Besin veritabanını yükler ve güncellenmişse yeniden uygular.
///
/// Katalogla aynı sürüm damgası deseni: dosyadaki sürüm profil
/// tablosundaki uygulanmış sürümden büyükse yerleşikler id bazında
/// tazeleniyor, kullanıcının sildiği geri gelmiyor.
const _foodsSeedVersionKey = 'foods.seededVersion';

Future<void> _seedFoods(ProviderContainer container) async {
  try {
    final json = await rootBundle.loadString('assets/foods.json');
    final db = container.read(appDatabaseProvider);
    final profile = ProfileRepository(db);

    await NutritionRepository(db).seedFromJson(
      json,
      readVersion: () async =>
          int.tryParse(await profile.read(_foodsSeedVersionKey) ?? '') ?? 0,
      writeVersion: (version) => profile.set(_foodsSeedVersionKey, '$version'),
    );
  } catch (error, stackTrace) {
    debugPrint('Besin tohumlaması başarısız: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

/// Serbest aktivite listesini yükler.
const _activitiesSeedVersionKey = 'activities.seededVersion';

Future<void> _seedActivities(ProviderContainer container) async {
  try {
    final json = await rootBundle.loadString('assets/activities.json');
    final db = container.read(appDatabaseProvider);
    final profile = ProfileRepository(db);

    await ActivitiesRepository(db).seedFromJson(
      json,
      readVersion: () async =>
          int.tryParse(await profile.read(_activitiesSeedVersionKey) ?? '') ??
          0,
      writeVersion: (version) =>
          profile.set(_activitiesSeedVersionKey, '$version'),
    );
  } catch (error, stackTrace) {
    debugPrint('Aktivite tohumlaması başarısız: $error');
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

/// Ölçüm türlerinin tanımlarını ilk açılışta ekler.
Future<void> _seedMetricDefinitions(ProviderContainer container) async {
  try {
    await MetricDefinitionsRepository(
      container.read(appDatabaseProvider),
    ).seedBuiltIns();
  } catch (error, stackTrace) {
    debugPrint('Ölçüm tohumlaması başarısız: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

/// Ekipman envanterini katalogdaki adlardan tohumlar.
///
/// Katalog tohumlamasından **sonra** çağrılmalı: liste kataloğun
/// içeriğinden türetiliyor. Kullanıcının eklediği hareketler yeni
/// ekipman getirirse sonraki açılışta o da listeye girer.
Future<void> _seedEquipment(ProviderContainer container) async {
  try {
    final db = container.read(appDatabaseProvider);
    final exercises = await CatalogRepository(db).watchFiltered().first;
    await EquipmentRepository(db).seedFrom(
      exercises.expand((Exercise exercise) => exercise.equipment),
    );
  } catch (error, stackTrace) {
    debugPrint('Ekipman tohumlaması başarısız: $error');
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
