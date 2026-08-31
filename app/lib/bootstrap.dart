import 'package:disport/app/app.dart';
import 'package:disport/features/catalog/data/catalog_repository.dart';
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
