import 'package:disport/app/app.dart';
import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/db/app_database.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/health/application/health_providers.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:disport/features/health/data/lab_repository.dart';
import 'package:disport/features/health/presentation/health_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sağlık ekranı testleri Drift **akışına** bağlanmaz.
///
/// Gerekçe `catalog_screen_test.dart`'takiyle aynı: `watch()` gerçek
/// async I/O, `testWidgets` sahte-async — `pumpAndSettle` asılır. Sorgu
/// davranışı `lab_repository_test.dart`'ta gerçek veritabanıyla zaten
/// doğrulanıyor.
///
/// Buna karşın `labRepositoryProvider` **gerçek** (bellek içi
/// veritabanıyla): ekleme formunun yazdığını gerçekten yazdığını
/// görmek için taklit yeterli olmazdı.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  LabEntry entry({
    required String id,
    required String marker,
    required String date,
    required double value,
    String unit = 'ng/mL',
    double? refLow = 30,
    double? refHigh = 100,
    String panel = LabPanels.vitamin,
  }) => LabEntry(
    id: id,
    date: date,
    marker: marker,
    value: value,
    unit: unit,
    refLow: refLow,
    refHigh: refHigh,
    panel: panel,
  );

  Widget wrap({
    Map<String, List<LabEntry>> labs = const {},
    List<DueSchedule> due = const [],
    Map<String, MetricSample> metrics = const {},
  }) => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      labsByPanelProvider.overrideWith((ref) => Stream.value(labs)),
      dueLabsProvider.overrideWith((ref) async => due),
      latestMetricsProvider.overrideWith((ref) => Stream.value(metrics)),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const HealthScreen(),
    ),
  );

  /// Yardım metinleri sayfayı uzattığı için Kaydet düğmesi test
  /// görüntü alanının (800x600) altında kalabiliyor; dokunmadan önce
  /// görünür kılınıyor.
  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('lab-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lab-save')));
    await tester.pumpAndSettle();
  }

  group('panel kartları', () {
    testWidgets('panel başlığı ve son değer görünür', (tester) async {
      await tester.pumpWidget(
        wrap(
          labs: {
            LabPanels.vitamin: [
              entry(
                id: '1',
                marker: 'Vitamin D',
                date: '2026-09-20',
                value: 24,
              ),
            ],
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vitamin'), findsOneWidget);
      expect(find.text('Vitamin D'), findsOneWidget);
      expect(find.text('24,0'), findsOneWidget);
      expect(find.text('ng/mL'), findsOneWidget);
    });

    testWidgets('referans dışı değer durum rozetiyle işaretlenir', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          labs: {
            LabPanels.vitamin: [
              entry(id: '1', marker: 'Vitamin D', date: '2026-09-20', value: 12),
            ],
          },
        ),
      );
      await tester.pumpAndSettle();

      // Renk tek başına anlam taşımaz: metin de var (ui-ux §1).
      expect(find.text('düşük'), findsOneWidget);
    });

    testWidgets('referans aralığı olmayan değer "bilinmiyor" olur', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          labs: {
            LabPanels.other: [
              entry(
                id: '1',
                marker: 'Ferritin',
                date: '2026-09-20',
                value: 40,
                refLow: null,
                refHigh: null,
              ),
            ],
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('aralık yok'), findsOneWidget);
      expect(find.text('düşük'), findsNothing);
    });

    testWidgets('önceki değere göre değişim gösterilir', (tester) async {
      await tester.pumpWidget(
        wrap(
          labs: {
            // Depo yeniden eskiye sıralı veriyor.
            LabPanels.vitamin: [
              entry(id: '2', marker: 'Vitamin D', date: '2026-09-20', value: 24),
              entry(id: '1', marker: 'Vitamin D', date: '2026-06-15', value: 10),
            ],
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('+14,0'), findsOneWidget);
      // Aynı marker iki kez listelenmemeli — satır son değeri gösterir.
      expect(find.text('Vitamin D'), findsOneWidget);
    });

    testWidgets('paneller sabit sırada dizilir', (tester) async {
      await tester.pumpWidget(
        wrap(
          labs: {
            LabPanels.vitamin: [
              entry(id: '1', marker: 'D', date: '2026-09-20', value: 40),
            ],
            LabPanels.metabolic: [
              entry(
                id: '2',
                marker: 'Açlık glukozu',
                date: '2026-09-20',
                value: 95,
                panel: LabPanels.metabolic,
              ),
            ],
          },
        ),
      );
      await tester.pumpAndSettle();

      // Metabolizma listede Vitamin'den önce gelir (LabPanels.ordered).
      final metabolic = tester.getTopLeft(find.text('Metabolizma')).dy;
      final vitamin = tester.getTopLeft(find.text('Vitamin')).dy;
      expect(metabolic, lessThan(vitamin));
    });
  });

  group('vade şeridi', () {
    testWidgets('vadesi gelen tahlil uyarı olarak çıkar', (tester) async {
      await tester.pumpWidget(
        wrap(
          due: [
            (
              marker: 'Vitamin D',
              nextDue: DateTime(2026, 8, 1),
              intervalMonths: 3,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Vitamin D'), findsWidgets);
      expect(find.textContaining('3 ayda bir'), findsOneWidget);
    });

    testWidgets('vade yoksa şerit hiç çizilmez', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('due-labs-banner')), findsNothing);
    });
  });

  group('boş durum', () {
    testWidgets('hiç tahlil yokken yönlendirme gösterilir', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.textContaining('Tahlil kaydı yok'), findsOneWidget);
    });
  });

  group('ölçümler', () {
    testWidgets('son ölçümler değerleriyle listelenir', (tester) async {
      await tester.pumpWidget(
        wrap(
          metrics: {
            MetricKinds.waist: (date: '2026-09-01', value: 104),
            MetricKinds.pushupMax: (date: '2026-09-01', value: 6),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bel çevresi'), findsOneWidget);
      expect(find.text('104,0'), findsOneWidget);
      // Tekrar sayısı ondalıksız gösterilir.
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('girilmemiş ölçüm sıfır değil boş gösterilir', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text('Bel çevresi'), findsOneWidget);
      expect(find.text('0,0'), findsNothing);
      expect(find.text('—'), findsWidgets);
    });
  });

  group('tahlil ekleme', () {
    testWidgets('form veritabanına yazar', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-lab-fab')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('lab-marker')),
        'Vitamin D',
      );
      await tester.enterText(find.byKey(const Key('lab-value')), '24');
      await tester.enterText(find.byKey(const Key('lab-unit')), 'ng/mL');
      await tester.enterText(find.byKey(const Key('lab-ref-low')), '30');
      await tester.enterText(find.byKey(const Key('lab-ref-high')), '100');
      await tester.pumpAndSettle();

      await save(tester);

      final saved = await LabRepository(db).latestPerMarker();
      expect(saved.single.marker, 'Vitamin D');
      expect(saved.single.value, 24);
      expect(saved.single.refLow, 30);
    });

    testWidgets('marker ya da değer boşken kaydedilmez', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-lab-fab')));
      await tester.pumpAndSettle();

      await save(tester);

      expect(find.text('Tahlil adı gerekli'), findsOneWidget);
      expect(await LabRepository(db).latestPerMarker(), isEmpty);
    });

    testWidgets('Türkçe ondalık virgülü kabul edilir', (tester) async {
      // Türkçe klavyede sayı tuş takımı virgül üretir; nokta beklemek
      // kullanıcıyı hataya iter.
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-lab-fab')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('lab-marker')), 'TSH');
      await tester.enterText(find.byKey(const Key('lab-value')), '2,45');
      await tester.enterText(find.byKey(const Key('lab-unit')), 'mIU/L');
      await tester.pumpAndSettle();

      await save(tester);

      final saved = await LabRepository(db).latestPerMarker();
      expect(saved.single.value, closeTo(2.45, 0.001));
    });
  });
}
