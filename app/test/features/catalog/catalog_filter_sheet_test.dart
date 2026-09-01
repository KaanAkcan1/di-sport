import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/catalog/presentation/catalog_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('filtre durumu', () {
    test('rozet yalnız GİZLİ filtreleri sayar', () {
      // Arama ve sekme zaten ekranda görünür; onları saymak kullanıcıyı
      // alt sayfada olmayan bir şeyi aramaya iterdi.
      const state = CatalogFilterState(
        query: 'şınav',
        location: ExerciseLocation.home,
      );
      expect(state.hiddenFilterCount, 0);
      expect(state.isActive, isTrue);
    });

    test('gizli filtreler tek tek sayılır', () {
      const state = CatalogFilterState(
        category: ExerciseCategory.strength,
        difficulty: 3,
        onlyMyEquipment: true,
      );
      expect(state.hiddenFilterCount, 3);
    });

    test('clearHidden aramayı ve sekmeyi bozmaz', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(catalogFilterProvider.notifier)
        ..setQuery('şınav')
        ..setLocation(ExerciseLocation.gym)
        ..toggleDifficulty(4)
        ..toggleOnlyMyEquipment();

      notifier.clearHidden();

      final state = container.read(catalogFilterProvider);
      expect(state.query, 'şınav');
      expect(state.location, ExerciseLocation.gym);
      expect(state.hiddenFilterCount, 0);
    });

    test('sekme seçimi toggle değil — aynı yere dokunmak kaldırmaz', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(catalogFilterProvider.notifier)
        ..setLocation(ExerciseLocation.home)
        ..setLocation(ExerciseLocation.home);

      expect(
        container.read(catalogFilterProvider).location,
        ExerciseLocation.home,
      );
    });

    test('zorluk çipi toggle — aynı seviyeye tekrar dokunmak kaldırır', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(catalogFilterProvider.notifier)
        ..toggleDifficulty(3)
        ..toggleDifficulty(3);

      expect(container.read(catalogFilterProvider).difficulty, isNull);
    });
  });

  group('alt sayfa', () {
    Widget wrap() => ProviderScope(
      overrides: [
        filteredExercisesProvider.overrideWith(
          (ref) => Stream.value(const <Exercise>[]),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: const Scaffold(body: CatalogFilterSheet()),
      ),
    );

    testWidgets('ekipman anahtarı ve zorluk seçenekleri çizilir', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('filter-my-equipment')), findsOneWidget);
      expect(find.text('Kuvvet'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('temizle düğmesi yalnız etkin filtre varken görünür', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clear-hidden-filters')), findsNothing);

      await tester.tap(find.text('Kuvvet'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clear-hidden-filters')), findsOneWidget);
    });

    testWidgets('sonuç sayısı kapanmadan görünür', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text('0 hareket'), findsOneWidget);
    });
  });
}
