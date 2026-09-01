import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:flutter/material.dart';

/// Değerin referans aralığındaki konumu (v3 §7.1).
///
/// Nokta-rengi-tek-başına dili terk edildi: çubuk hedef bandı, imleç
/// değeri gösteriyor; satırdaki metin aralığı zaten yazıyor. Ölçek
/// aralığın iki yanına %35 pay bırakır — bandın dışına taşan değer de
/// çubukta görünür kalır, kaybolmaz.
class LabRangeBar extends StatelessWidget {
  const LabRangeBar({
    super.key,
    required this.value,
    required this.low,
    required this.high,
    required this.inRange,
  });

  final double value;
  final double low;
  final double high;
  final bool inRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;

    final span = (high - low).abs();
    // Dejenere aralıkta (low == high) çubuk çizilemez.
    if (span <= 0) return const SizedBox.shrink();

    final scaleMin = low - span * 0.35;
    final scaleMax = high + span * 0.35;
    double fraction(double v) =>
        ((v - scaleMin) / (scaleMax - scaleMin)).clamp(0.0, 1.0);

    final marker = inRange ? semantic.success : semantic.danger;

    return SizedBox(
      height: 12,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Zemin çizgisi.
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              // Hedef bant.
              Positioned(
                left: width * fraction(low),
                width: width * (fraction(high) - fraction(low)),
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: semantic.successSurface,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: semantic.success, width: 0.5),
                  ),
                ),
              ),
              // Değer imleci.
              Positioned(
                left: (width * fraction(value) - 4).clamp(0.0, width - 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: marker,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
