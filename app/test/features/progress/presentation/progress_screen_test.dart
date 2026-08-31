import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:disport/features/progress/application/progress_providers.dart';
import 'package:disport/features/progress/domain/transition_criteria.dart';
import 'package:disport/features/progress/domain/weekly_summary.dart';
import 'package:disport/features/progress/domain/weight_trend.dart';
import 'package:disport/features/progress/presentation/progress_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ekran testi hesap yapmaz, hesabın **gösterimini** sınar.
///
/// `movingAverage` / `summarizeWeeks` / `evaluateTransition` kendi saf
/// testlerinde doğrulanıyor; burada aynı sayıları tekrar sınamak
/// katmanları karıştırmak olurdu. Bu yüzden `progressViewProvider`
/// hazır bir nesneyle değiştiriliyor.
void main() {
  List<WeightPoint> weights({int days = 14}) => [
    for (var i = 0; i < days; i++)
      (
        date: '2026-09-${(i + 1).toString().padLeft(2, '0')}',
        value: 110.0 - i * 0.1,
      ),
  ];

  WeekSummary week({
    int index = 1,
    double? avg = 109.7,
    double? delta,
    int gymDone = 3,
    int homeDone = 4,
    int slipDays = 0,
    int dayCount = 7,
  }) => WeekSummary(
    weekIndex: index,
    dayCount: dayCount,
    avgWeight: avg,
    deltaFromPrevWeek: delta,
    gymDone: gymDone,
    gymTarget: 3,
    homeDone: homeDone,
    homeTarget: 4,
    restDays: 0,
    slipDays: slipDays,
  );

  ProgressViewData view({
    List<WeightPoint>? points,
    List<WeekSummary> weeks = const [],
    Map<String, MetricSample> latest = const {},
    TransitionCriteria? criteria,
    bool hasPlan = true,
  }) {
    final series = points ?? weights();
    return ProgressViewData(
      weights: series,
      trend: movingAverage(series),
      weeks: weeks,
      latestMetrics: latest,
      criteria:
          criteria ??
          evaluateTransition(
            latestWeight: null,
            latestPushupMax: null,
            painFreeConfirmed: false,
          ),
      hasPlan: hasPlan,
    );
  }

  /// [onPainFree] verilirse ağrı onayı yazma kapısı taklitle
  /// değiştirilir; verilmezse gerçek provider (veritabanına yazar)
  /// kalır ve test ona hiç dokunmaz.
  Widget wrap(
    ProgressViewData data, {
    Future<void> Function(bool)? onPainFree,
  }) => ProviderScope(
    overrides: [
      progressViewProvider.overrideWith((ref) async => data),
      if (onPainFree != null)
        setPainFreeConfirmedProvider.overrideWith((ref) => onPainFree),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: ProgressScreen()),
    ),
  );

  group('kilo grafiği', () {
    testWidgets('iki seri çizilir: ham veri ve hareketli ortalama', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(view()));
      await tester.pumpAndSettle();

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineBarsData, hasLength(2));

      // Ortalama çizgisi ham veriden kalın: göz önce ona gitmeli.
      final raw = chart.data.lineBarsData[0];
      final trend = chart.data.lineBarsData[1];
      expect(trend.barWidth, greaterThan(raw.barWidth));
      expect(trend.spots, hasLength(14));
    });

    testWidgets('tek ölçümde de çökmez', (tester) async {
      await tester.pumpWidget(wrap(view(points: weights(days: 1))));
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('haftalık kartlar', () {
    testWidgets('hedef sayaçları ve kaçak gösterilir', (tester) async {
      await tester.pumpWidget(
        wrap(view(weeks: [week(), week(index: 2, delta: -0.7, slipDays: 1)])),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hafta 1'), findsOneWidget);
      expect(find.text('Salon 3 / 3'), findsWidgets);
      expect(find.text('Ev 4 / 4'), findsWidgets);
      expect(find.text('Kaçak yok'), findsOneWidget);
      expect(find.text('1 kaçak gün'), findsOneWidget);
      expect(find.text('-0,7 kg'), findsOneWidget);
    });

    testWidgets('süren hafta işaretlenir', (tester) async {
      await tester.pumpWidget(
        wrap(view(weeks: [week(dayCount: 3, gymDone: 1, homeDone: 1)])),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('sürüyor'), findsOneWidget);
    });

    testWidgets('plan yoksa haftalık yerine yönlendirme çıkar', (tester) async {
      await tester.pumpWidget(wrap(view(hasPlan: false)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Haftalık özet için plan gerekli'),
          findsOneWidget);
    });
  });

  group('geçiş kartı', () {
    testWidgets('sağlanmayan ölçütler ve eksik veri gösterilir', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(view()));
      await tester.pumpAndSettle();

      expect(find.textContaining('0 / 3 ölçüt sağlandı'), findsOneWidget);
      expect(find.text('henüz tartılmadı'), findsOneWidget);
      expect(find.text('henüz ölçülmedi'), findsOneWidget);
    });

    testWidgets('üçü sağlanınca kart bunu söyler', (tester) async {
      await tester.pumpWidget(
        wrap(
          view(
            latest: {
              MetricKinds.weight: (date: '2026-09-14', value: 103.2),
              MetricKinds.pushupMax: (date: '2026-09-14', value: 11),
            },
            criteria: evaluateTransition(
              latestWeight: 103.2,
              latestPushupMax: 11,
              painFreeConfirmed: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Üç ölçüt de sağlandı'), findsOneWidget);
      expect(find.text('şu an 103,2 kg'), findsOneWidget);
      // Şınav sayısı ondalıksız.
      expect(find.text('şu an 11'), findsOneWidget);
    });

    testWidgets('ağrı onayı anahtarı profile yazar', (tester) async {
      var written = false;

      await tester.pumpWidget(
        wrap(view(), onPainFree: (value) async => written = value),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pain-free-switch')));
      await tester.pumpAndSettle();

      expect(written, isTrue);
    });
  });

  group('boş durum', () {
    testWidgets('hiç veri yokken tartı girmeye yönlendirir', (tester) async {
      await tester.pumpWidget(wrap(view(points: const [], hasPlan: false)));
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.textContaining('Bugün sekmesinden tartını gir'),
          findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });
  });
}
