import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_number.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/nutrition/domain/food.dart';
import 'package:disport/features/nutrition/domain/meal_math.dart';
import 'package:disport/features/nutrition/presentation/food_labels.dart';
import 'package:flutter/material.dart';

/// Porsiyon sayfasının sonucu.
class PortionChoice {
  const PortionChoice({
    required this.food,
    required this.quantity,
    this.portion,
    this.customGrams,
  });

  final Food food;
  final double quantity;
  final FoodPortion? portion;
  final double? customGrams;
}

/// "3 porsiyon yedim" sayfası.
///
/// Ana giriş **çarpan**, gram değil: kullanıcı tabağını tartmıyor, kaç
/// kase yediğini biliyor. Gram alanı bir kaçış yolu olarak duruyor ve
/// dolduruldğunda porsiyonu eziyor.
Future<PortionChoice?> showPortionSheet(
  BuildContext context, {
  required Food food,
}) => showModalBottomSheet<PortionChoice>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _PortionSheet(food: food),
);

class _PortionSheet extends StatefulWidget {
  const _PortionSheet({required this.food});

  final Food food;

  @override
  State<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<_PortionSheet> {
  late FoodPortion? _portion = widget.food.defaultPortion;
  double _quantity = 1;
  final _gramsController = TextEditingController();

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  double? get _customGrams {
    final raw = _gramsController.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    final value = double.tryParse(raw);
    return (value != null && value > 0) ? value : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = mealValues(
      food: widget.food,
      quantity: _quantity,
      portion: _portion,
      customGrams: _customGrams,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            foodDisplayName(context, widget.food),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),

          if (widget.food.portions.length > 1) ...[
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final portion in widget.food.portions)
                  ChoiceChip(
                    label: Text(portionLabel(context, portion)),
                    selected: _portion?.id == portion.id,
                    onSelected: (_) => setState(() => _portion = portion),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          _QuantityStepper(
            label: _portion == null
                ? context.l10n.portionUnitGrams100
                : portionLabel(context, _portion!),
            quantity: _quantity,
            // Yarım porsiyon sık; adım 0.5 seçildi. Tam sayı adımı
            // "yarım kase çorba içtim" diyen kullanıcıyı gram alanına
            // itiyordu.
            onChanged: (value) => setState(() => _quantity = value),
          ),
          const SizedBox(height: AppSpacing.lg),

          TextField(
            controller: _gramsController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: context.l10n.portionCustomGramsLabel,
              helperText: context.l10n.portionCustomGramsHelper,
              suffixText: 'g',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.xl),

          AppMetricStrip([
            AppMetric(
              caption: context.l10n.portionGrams,
              value: TurkishNumber.format(values.grams),
              unit: 'g',
            ),
            AppMetric(
              caption: context.l10n.portionKcal,
              value: values.kcal.round().toString(),
              unit: 'kcal',
            ),
            AppMetric(
              caption: context.l10n.portionProtein,
              value: TurkishNumber.format(values.protein, fractionDigits: 1),
              unit: 'g',
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(
                PortionChoice(
                  food: widget.food,
                  quantity: _quantity,
                  portion: _portion,
                  customGrams: _customGrams,
                ),
              ),
              child: Text(context.l10n.portionAddToMeal),
            ),
          ),
        ],
      ),
    );
  }
}

/// `− n +` çarpanı.
class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.label,
    required this.quantity,
    required this.onChanged,
  });

  final String label;
  final double quantity;
  final ValueChanged<double> onChanged;

  static const _step = 0.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: quantity > _step
              ? () => onChanged(quantity - _step)
              : null,
          icon: const Icon(Icons.remove),
          tooltip: context.l10n.portionDecrease,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                TurkishNumber.format(quantity),
                style: theme.textTheme.headlineSmall,
              ),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => onChanged(quantity + _step),
          icon: const Icon(Icons.add),
          tooltip: context.l10n.portionIncrease,
        ),
      ],
    );
  }
}
