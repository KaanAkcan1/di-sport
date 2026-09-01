import 'dart:convert';

import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/ai_bridge/domain/plan_importer.dart';
import 'package:disport/features/ai_bridge/presentation/import_plan_sheet.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ai_fixtures.dart';

void main() {
  late List<FullPlan> insertedPlans;
  late List<Exercise> addedExercises;

  setUp(() {
    insertedPlans = [];
    addedExercises = [];
  });

  Widget wrap() => ProviderScope(
    overrides: [
      planValidatorProvider.overrideWith((ref) async => fixtureValidator()),
      planImporterProvider.overrideWithValue(
        PlanImporter(
          insertPlan: (plan) async => insertedPlans.add(plan),
          addExercise: (exercise) async => addedExercises.add(exercise),
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: const Scaffold(body: ImportPlanSheet()),
    ),
  );

  Future<void> paste(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('plan-json-field')), text);
    await tester.pumpAndSettle();
  }

  Future<void> validateTap(WidgetTester tester) async {
    await tester.tap(find.text('Doğrula'));
    await tester.pumpAndSettle();
  }

  /// Önizleme uzun; "İçeri al" düğmesi test görüntü alanının altında
  /// kalabiliyor. Dokunmadan önce görünür kılınıyor.
  Future<void> importTap(WidgetTester tester) async {
    await tester.ensureVisible(find.text('İçeri al'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('İçeri al'));
    await tester.pumpAndSettle();
  }

  testWidgets('bozuk JSON yapıştırılabilir hata gösterir', (tester) async {
    await tester.pumpWidget(wrap());
    await paste(tester, '{bozuk');
    await validateTap(tester);

    expect(find.text('Plan alınamadı'), findsOneWidget);
    expect(find.textContaining('JSON ayrıştırılamadı'), findsOneWidget);
    expect(find.text('Hatayı kopyala'), findsOneWidget);
    expect(find.textContaining('yapay zekâya yapıştır'), findsOneWidget);
  });

  testWidgets('anlam hatası alan yoluyla gösterilir', (tester) async {
    final document = validPlanMap();
    (document['days'] as List).removeLast();

    await tester.pumpWidget(wrap());
    await paste(tester, jsonEncode(document));
    await validateTap(tester);

    expect(find.textContaining('7 gün bekleniyordu'), findsOneWidget);
  });

  testWidgets('geçerli belge önizleme gösterir, henüz yazmaz', (tester) async {
    await tester.pumpWidget(wrap());
    await paste(tester, validPlanJson());
    await validateTap(tester);

    expect(find.text('Eylül Planı'), findsOneWidget);
    expect(find.textContaining('1 hafta · 7 gün'), findsOneWidget);
    expect(find.text('Salon 1'), findsOneWidget);
    expect(find.text('Ev 5'), findsOneWidget);
    expect(find.text('Dinlenme 1'), findsOneWidget);

    // Onaylanmadan hiçbir şey yazılmamalı (spec 7.3, dördüncü kapı).
    expect(insertedPlans, isEmpty);
  });

  testWidgets('içeri al düğmesi planı yazar', (tester) async {
    await tester.pumpWidget(wrap());
    await paste(tester, validPlanJson());
    await validateTap(tester);

    await importTap(tester);

    expect(insertedPlans, hasLength(1));
    expect(insertedPlans.single.title, 'Eylül Planı');
    expect(insertedPlans.single.days, hasLength(7));
  });

  testWidgets('metin değişince önceki önizleme geçersizleşir', (tester) async {
    await tester.pumpWidget(wrap());
    await paste(tester, validPlanJson());
    await validateTap(tester);
    expect(find.text('İçeri al'), findsOneWidget);

    await paste(tester, '{başka bir şey');
    expect(find.text('İçeri al'), findsNothing);
  });

  group('yeni hareketler', () {
    String documentWithNew() {
      final document = validPlanMap();
      (document['newExercises'] as List).add(validNewExercise());
      return jsonEncode(document);
    }

    testWidgets('önizlemede işaretli gelir ve kataloğa eklenir', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await paste(tester, documentWithNew());
      await validateTap(tester);

      expect(find.text('Yeni hareket önerileri'), findsOneWidget);
      final tile = tester.widget<CheckboxListTile>(
        find.byKey(const Key('accept-custom_burpee')),
      );
      expect(tile.value, isTrue);

      await importTap(tester);

      expect(addedExercises.single.id, 'custom_burpee');
      expect(addedExercises.single.isUserDefined, isTrue);
    });

    testWidgets('işaret kaldırılırsa kataloğa eklenmez', (tester) async {
      await tester.pumpWidget(wrap());
      await paste(tester, documentWithNew());
      await validateTap(tester);

      await tester.tap(find.byKey(const Key('accept-custom_burpee')));
      await tester.pumpAndSettle();

      await importTap(tester);

      expect(addedExercises, isEmpty);
      expect(insertedPlans, hasLength(1));
    });

    testWidgets('yeni hareket yoksa bölüm hiç çıkmaz', (tester) async {
      await tester.pumpWidget(wrap());
      await paste(tester, validPlanJson());
      await validateTap(tester);

      expect(find.text('Yeni hareket önerileri'), findsNothing);
    });
  });
}
