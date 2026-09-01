import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:disport/features/progress/application/progress_providers.dart';
import 'package:disport/features/progress/domain/transition_criteria.dart';
import 'package:flutter_test/flutter_test.dart';

ProgressViewData viewWith(List<double> weights) => ProgressViewData(
  weights: [
    for (final (index, kg) in weights.indexed)
      (date: '2026-08-${(index + 1).toString().padLeft(2, '0')}', value: kg),
  ],
  trend: const [],
  weeks: const [],
  latestMetrics: const <String, MetricSample>{},
  criteria: evaluateTransition(
    latestWeight: null,
    latestPushupMax: null,
    painFreeConfirmed: false,
  ),
  hasPlan: false,
);

void main() {
  test('tartı yokken toplam değişim yok', () {
    expect(viewWith(const []).totalChangeKg, isNull);
  });

  test('tek tartıyla değişim yok — kıyas noktası yok', () {
    // "0,0 kg" yazmak ilerleme olmadığını söylerdi; oysa henüz
    // karşılaştıracak ikinci bir ölçüm yok.
    expect(viewWith(const [110.0]).totalChangeKg, isNull);
  });

  test('kayıp negatif çıkar', () {
    expect(viewWith(const [110.0, 107.2]).totalChangeKg, closeTo(-2.8, 0.001));
  });

  test('artış pozitif çıkar', () {
    expect(viewWith(const [107.0, 108.5]).totalChangeKg, closeTo(1.5, 0.001));
  });

  test('aradaki oynamalar değil ilk ve son sayılır', () {
    // Kahraman rakam toplam yolu gösteriyor; ara dalgalanma grafiğin işi.
    expect(
      viewWith(const [110.0, 112.0, 108.0, 107.0]).totalChangeKg,
      closeTo(-3.0, 0.001),
    );
  });
}
