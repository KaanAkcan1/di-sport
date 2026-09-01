import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart'
    show foodByIdProvider;
import 'package:disport/features/nutrition/presentation/food_labels.dart';
import 'package:disport/features/nutrition/presentation/food_picker_screen.dart';
import 'package:disport/features/plan/application/plan_editor_providers.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/plan/domain/meal_kind.dart';
import 'package:disport/features/plan/presentation/slot_kind_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Slot düzenleme: saat, tür, (öğünse) hangi öğün, etiket, not.
///
/// [slot] null ise yeni slot ekleniyor. Aynı sayfa iki iş yapıyor
/// çünkü alanlar birebir aynı; iki sayfa yazmak ikisini ayrı ayrı
/// bozulabilir hâle getirirdi.
Future<void> showSlotEditorSheet(
  BuildContext context, {
  required String dayId,
  PlanSlot? slot,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _SlotEditor(dayId: dayId, slot: slot),
);

class _SlotEditor extends ConsumerStatefulWidget {
  const _SlotEditor({required this.dayId, this.slot});

  final String dayId;
  final PlanSlot? slot;

  @override
  ConsumerState<_SlotEditor> createState() => _SlotEditorState();
}

class _SlotEditorState extends ConsumerState<_SlotEditor> {
  late TimeOfDay _time = _parseTime(widget.slot?.time ?? '08:00');
  late SlotKind _kind = widget.slot?.kind ?? SlotKind.meal;
  late MealKind? _mealKind = widget.slot?.mealKind ?? MealKind.kahvalti;
  late final _label = TextEditingController(text: widget.slot?.label ?? '');
  late final _note = TextEditingController(text: widget.slot?.note ?? '');
  late List<PlanMealItem> _items = [...?widget.slot?.items];
  String? _error;

  static TimeOfDay _parseTime(String raw) {
    final parts = raw.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 8,
      minute: int.tryParse(parts.last) ?? 0,
    );
  }

  String get _timeText =>
      '${_time.hour.toString().padLeft(2, '0')}:'
      '${_time.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _label.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.slot == null ? l10n.planSlotNew : l10n.planSlotEdit,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (widget.slot case final existing?)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.commonDelete,
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await ref
                        .read(planEditorRepositoryProvider)
                        .deleteSlot(existing.id);
                    await ref.read(planChangedProvider)();
                    navigator.pop();
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(l10n.planSlotTime),
            trailing: Text(
              _timeText,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _time,
              );
              if (picked != null) setState(() => _time = picked);
            },
          ),

          const SizedBox(height: AppSpacing.md),
          Text(l10n.planSlotKind),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final kind in SlotKind.values)
                ChoiceChip(
                  avatar: Icon(slotKindIcon(kind), size: 18),
                  label: Text(slotKindLabel(context, kind)),
                  selected: _kind == kind,
                  onSelected: (_) => setState(() => _kind = kind),
                ),
            ],
          ),

          // Öğün türü yalnız öğün slotunda soruluyor: bir antrenmanın
          // "hangi öğün" olduğu sorusunun cevabı yok.
          if (_kind == SlotKind.meal) ...[
            const SizedBox(height: AppSpacing.md),
            Text(l10n.planSlotMealKind),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final meal in MealKind.values)
                  ChoiceChip(
                    label: Text(mealKindLabel(context, meal)),
                    selected: _mealKind == meal,
                    onSelected: (_) => setState(() => _mealKind = meal),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Öğün kalemleri (v3 §5.0): plana besin id'siyle bağlanan
            // satırlar. "Plandaki gibi yedim" tek dokunuşu bunları okur.
            Text(l10n.planSlotItems),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final (index, item) in _items.indexed)
                  _ItemChip(
                    key: Key('slot-item-$index'),
                    item: item,
                    onDeleted: () =>
                        setState(() => _items = [..._items]..removeAt(index)),
                  ),
                ActionChip(
                  key: const Key('slot-add-item'),
                  avatar: const Icon(Icons.add, size: 16),
                  label: Text(l10n.planSlotAddItem),
                  onPressed: _pickItem,
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _label,
            decoration: InputDecoration(
              labelText: l10n.planSlotLabel,
              errorText: _error,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l10n.planSlotNote),
          ),
          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _save, child: Text(l10n.commonSave)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickItem() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FoodPickerScreen(
          mealKind: _mealKind ?? MealKind.kahvalti,
          onPicked: (choice) => setState(
            () => _items = [
              ..._items,
              PlanMealItem(
                foodId: choice.food.id,
                // Elle gram girildiyse 100 g tabanına çevrilir: plan
                // kalemi gram değil çarpan taşıyor (null porsiyon =
                // 100 g × çarpan) ve 180 g = 1,8 çarpan aynı kaloriyi
                // verir.
                quantity: choice.customGrams != null
                    ? choice.customGrams! / 100
                    : choice.quantity,
                portionId: choice.customGrams != null
                    ? null
                    : choice.portion?.id,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = context.l10n;

    if (_label.text.trim().isEmpty) {
      setState(() => _error = l10n.planSlotLabelRequired);
      return;
    }
    if (_kind == SlotKind.meal && _mealKind == null) {
      setState(() => _error = l10n.planSlotMealKindRequired);
      return;
    }

    final navigator = Navigator.of(context);
    await ref
        .read(planEditorRepositoryProvider)
        .upsertSlot(
          widget.dayId,
          slotId: widget.slot?.id,
          time: _timeText,
          kind: _kind,
          mealKind: _mealKind,
          items: _items,
          label: _label.text,
          note: _note.text.trim().isEmpty ? null : _note.text,
        );
    await ref.read(planChangedProvider)();
    navigator.pop();
  }
}

/// Kalem çipi — adı id'den çözer; besin yüklenene dek id gösterir.
class _ItemChip extends ConsumerWidget {
  const _ItemChip({super.key, required this.item, required this.onDeleted});

  final PlanMealItem item;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final food = ref.watch(foodByIdProvider(item.foodId)).value;
    final name = food == null ? item.foodId : foodDisplayName(context, food);
    final quantityText = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.toInt().toString()
        : item.quantity.toStringAsFixed(1).replaceAll('.', ',');

    return InputChip(
      label: Text('$name ×$quantityText'),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close, size: 15),
    );
  }
}
