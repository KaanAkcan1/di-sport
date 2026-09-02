import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_text.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/catalog/domain/recent_exercise_source.dart';
import 'package:disport/features/catalog/presentation/catalog_screen.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart';
import 'package:disport/features/nutrition/domain/activity.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../exercise_fixtures.dart';

/// Ekran testleri veritabanına dokunmaz.
///
/// Drift'in `watch()` akışı gerçek async I/O ile gelir; `testWidgets`
/// sahte-async bölgesinde çalıştığı için `pumpAndSettle` o akışı
/// bekleyerek asılı kalır. Ayrıca sorgu davranışı zaten
/// `catalog_repository_test.dart` içinde gerçek veritabanıyla
/// doğrulanıyor — burada tekrar test etmek katmanları karıştırmak olur.
///
/// Bu yüzden `filteredExercisesProvider` bellekteki bir listeyle
/// değiştiriliyor; filtreleme mantığı gerçeğiyle aynı katlamayı kullanan
/// küçük bir taklitle taşınıyor, böylece arama kutusu ile durum
/// arasındaki bağ yine sınanmış oluyor.
void main() {
  final catalog = [
    fixtureExercise(
      id: 'incline_pushup',
      nameTr: 'Eğimli Şınav',
      nameEn: 'Incline Push-Up',
      muscles: ['göğüs'],
    ),
    fixtureExercise(
      id: 'chair_squat',
      nameTr: 'Sandalyeye Squat',
      nameEn: 'Chair Squat',
      muscles: ['bacak'],
    ),
    fixtureExercise(
      id: 'plank',
      nameTr: 'Plank',
      nameEn: 'Plank',
      muscles: ['karın'],
      location: ExerciseLocation.both,
      category: ExerciseCategory.core,
    ),
    fixtureExercise(
      id: 'stationary_bike',
      nameTr: 'Kondisyon Bisikleti',
      nameEn: 'Stationary Bike',
      muscles: ['bacak'],
      location: ExerciseLocation.gym,
      category: ExerciseCategory.cardio,
    ),
  ];

  List<Exercise> applyFilter(CatalogFilterState filter) {
    final needle = TurkishText.fold(filter.query.trim());
    return catalog.where((e) {
      if (needle.isNotEmpty) {
        final haystack = TurkishText.fold(
          [e.displayNameTr, e.nameEn, ...e.primaryMuscles].join(' '),
        );
        if (!haystack.contains(needle)) return false;
      }
      if (filter.location != null &&
          e.location != filter.location &&
          e.location != ExerciseLocation.both) {
        return false;
      }
      if (filter.category != null && e.category != filter.category) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => a.displayNameTr.compareTo(b.displayNameTr));
  }

  Widget wrap() => ProviderScope(
    overrides: [
      filteredExercisesProvider.overrideWith(
        (ref) => Stream.value(applyFilter(ref.watch(catalogFilterProvider))),
      ),
      // "Son yaptıkların" antrenman kayıtlarını okuyor; ekran testi
      // Drift akışına bağlanmamalı (asılır).
      recentExercisesProvider.overrideWith(
        (ref) => Stream.value(const <RecentExercise>[]),
      ),
      // Dışarıda sekmesi aktiviteleri veritabanından okuyor; ekran
      // testi Drift akışına bağlanmamalı (asılır).
      activityCatalogProvider('').overrideWith(
        (ref) => Stream.value(const <Activity>[]),
      ),
      todayIsoProvider.overrideWithValue('2026-09-01'),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: const Scaffold(body: CatalogScreen()),
    ),
  );

  testWidgets('hareketleri listeler ve sayısını gösterir', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // Yer artık bir bağlam: ekran "Evde" sekmesiyle açılıyor, salona
    // özel hareket burada görünmüyor (M12).
    expect(find.text('Incline Push-Up (Eğimli Şınav)'), findsOneWidget);
    expect(find.text('Chair Squat (Sandalyeye Squat)'), findsOneWidget);
    expect(find.text('Plank'), findsOneWidget, reason: '"both" her sekmede');
    expect(find.text('Stationary Bike (Kondisyon Bisikleti)'), findsNothing);
    expect(_countLabel(tester), '3');
  });

  testWidgets('arama listeyi daraltır', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'squat');
    await tester.pumpAndSettle();

    expect(find.text('Chair Squat (Sandalyeye Squat)'), findsOneWidget);
    expect(find.text('Incline Push-Up (Eğimli Şınav)'), findsNothing);
    expect(_countLabel(tester), '1');
  });

  testWidgets('aksansız arama Türkçe kaydı bulur', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'sinav');
    await tester.pumpAndSettle();

    expect(find.text('Incline Push-Up (Eğimli Şınav)'), findsOneWidget);
  });

  testWidgets('kas adıyla arama çalışır', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'karın');
    await tester.pumpAndSettle();

    expect(find.text('Plank'), findsOneWidget);
    expect(_countLabel(tester), '1');
  });

  testWidgets('yer sekmesi listeyi değiştirir', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salonda'));
    await tester.pumpAndSettle();

    expect(find.text('Stationary Bike (Kondisyon Bisikleti)'), findsOneWidget);
    expect(find.text('Chair Squat (Sandalyeye Squat)'), findsNothing);
    // 'both' olan hareket her iki sekmede de görünür.
    expect(find.text('Plank'), findsOneWidget);

    await tester.tap(find.text('Evde'));
    await tester.pumpAndSettle();
    expect(find.text('Chair Squat (Sandalyeye Squat)'), findsOneWidget);
  });

  testWidgets('sekme seçili yeri korur — tekrar dokunmak sıfırlamaz', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salonda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salonda'));
    await tester.pumpAndSettle();

    expect(find.text('Stationary Bike (Kondisyon Bisikleti)'), findsOneWidget);
  });

  testWidgets('kategori filtresi alt sayfadan uygulanır', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salonda'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-filters')));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Kardiyo'));
    await tester.pumpAndSettle();

    // Alt sayfa kapanmadan sonuç değişiyor; kapatınca liste süzülü.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Stationary Bike (Kondisyon Bisikleti)'), findsOneWidget);
    expect(find.text('Plank'), findsNothing);
  });

  testWidgets('etkin filtre silinebilir etiket olarak görünür', (tester) async {
    // Neyin süzüldüğü hep görünür olmalı; katalog sessizce küçülmemeli.
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Gövde'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byType(InputChip), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets('sonuç yoksa yol gösteren boş durum ve temizleme', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();

    expect(find.text('Eşleşen hareket yok'), findsOneWidget);

    await tester.tap(find.text('Filtreleri temizle'));
    await tester.pumpAndSettle();

    expect(find.text('Incline Push-Up (Eğimli Şınav)'), findsOneWidget);
    // Filtre temizlenince arama kutusu da boşalmalı; yazı kalırsa
    // kullanıcı dolu listeyi filtreli sanır.
    expect(find.text('zzzz'), findsNothing);
  });

  testWidgets('arama kutusundaki temizle düğmesi', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.clear), findsNothing);

    await tester.enterText(find.byType(TextField), 'plank');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    expect(_countLabel(tester), '3');
  });
}

/// Bölüm etiketinin sağındaki sayı — M12'de "4 hareket" yerine
/// başlık satırının sonunda salt rakam duruyor.
String _countLabel(WidgetTester tester) {
  final label = find.ancestor(
    of: find.text('HAREKETLER'),
    matching: find.byType(AppSectionLabel),
  );
  return tester
      .widget<Text>(find.descendant(of: label, matching: find.byType(Text)).last)
      .data!;
}
