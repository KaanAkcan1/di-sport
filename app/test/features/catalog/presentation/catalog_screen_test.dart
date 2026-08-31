import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/utils/turkish_text.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/catalog/presentation/catalog_screen.dart';
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
          [e.nameTr, e.nameEn, ...e.primaryMuscles].join(' '),
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
    }).toList()..sort((a, b) => a.nameTr.compareTo(b.nameTr));
  }

  Widget wrap() => ProviderScope(
    overrides: [
      filteredExercisesProvider.overrideWith(
        (ref) => Stream.value(applyFilter(ref.watch(catalogFilterProvider))),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: CatalogScreen()),
    ),
  );

  testWidgets('hareketleri listeler ve sayısını gösterir', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Eğimli Şınav'), findsOneWidget);
    expect(find.text('Sandalyeye Squat'), findsOneWidget);
    expect(find.text('Plank'), findsOneWidget);
    expect(find.text('4 hareket'), findsOneWidget);
  });

  testWidgets('arama listeyi daraltır', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'squat');
    await tester.pumpAndSettle();

    expect(find.text('Sandalyeye Squat'), findsOneWidget);
    expect(find.text('Eğimli Şınav'), findsNothing);
    expect(find.text('1 hareket'), findsOneWidget);
  });

  testWidgets('aksansız arama Türkçe kaydı bulur', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'sinav');
    await tester.pumpAndSettle();

    expect(find.text('Eğimli Şınav'), findsOneWidget);
  });

  testWidgets('kas adıyla arama çalışır', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'karın');
    await tester.pumpAndSettle();

    expect(find.text('Plank'), findsOneWidget);
    expect(find.text('1 hareket'), findsOneWidget);
  });

  testWidgets('konum filtresi uygulanır, tekrar dokununca kalkar', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Salon'));
    await tester.pumpAndSettle();
    expect(find.text('Kondisyon Bisikleti'), findsOneWidget);
    expect(find.text('Sandalyeye Squat'), findsNothing);
    // 'both' olan Plank salon filtresinde de görünmeli
    expect(find.text('Plank'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Salon'));
    await tester.pumpAndSettle();
    expect(find.text('Sandalyeye Squat'), findsOneWidget);
  });

  testWidgets('kategori filtresi uygulanır', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Kardiyo'));
    await tester.pumpAndSettle();

    expect(find.text('Kondisyon Bisikleti'), findsOneWidget);
    expect(find.text('Plank'), findsNothing);
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

    expect(find.text('Eğimli Şınav'), findsOneWidget);
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
    expect(find.text('4 hareket'), findsOneWidget);
  });
}
