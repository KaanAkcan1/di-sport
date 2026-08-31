import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/workout/presentation/workout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Günün saatleri: öğünler, antrenman, uyku, ölçüm, tahlil.
///
/// Antrenman slotu diğerlerinden farklı: işaretlenmiyor, dokununca
/// Antrenman ekranını açıyor. Kutucuk oradaki setler tamamlandıkça
/// kendiliğinden doluyor.
class SlotList extends ConsumerWidget {
  const SlotList({super.key, required this.day});

  final FullPlanDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(todayLogProvider).value;
    final iso = ref.watch(todayIsoProvider);

    return Column(
      children: [
        for (final slot in day.slots)
          if (slot.kind == SlotKind.workout)
            _WorkoutCard(day: day, slot: slot)
          else
            _SlotTile(
              slot: slot,
              checked: log?.isSlotChecked(slot.id) ?? false,
              onToggle: () =>
                  ref.read(todayRepositoryProvider).toggleSlot(iso, slot.id),
            ),
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.checked,
    required this.onToggle,
  });

  final PlanSlot slot;
  final bool checked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CheckboxListTile(
      value: checked,
      onChanged: (_) => onToggle(),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(
        slot.label,
        style: theme.textTheme.bodyLarge?.copyWith(
          // İşaretlenen öğün üstü çizili: tamamlananla kalanı bir bakışta
          // ayırmak, renkten bağımsız olarak da işe yarar.
          decoration: checked ? TextDecoration.lineThrough : null,
          color: checked ? theme.colorScheme.onSurfaceVariant : null,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(
            slot.kind.icon,
            size: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            slot.time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Antrenman slotu — dokununca Antrenman ekranı açılır.
class _WorkoutCard extends ConsumerWidget {
  const _WorkoutCard({required this.day, required this.slot});

  final FullPlanDay day;
  final PlanSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final done = ref.watch(todayLogProvider).value?.workoutDone ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      color: done
          ? theme.colorScheme.surfaceContainerLow
          : theme.colorScheme.primaryContainer,
      child: ListTile(
        leading: Icon(
          done ? Icons.check_circle : Icons.fitness_center,
          color: done
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onPrimaryContainer,
        ),
        title: Text(
          slot.label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: done ? null : theme.colorScheme.onPrimaryContainer,
          ),
        ),
        subtitle: Text(
          '${slot.time} · ${day.exercises.length} hareket',
          style: theme.textTheme.bodySmall?.copyWith(
            color: done
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onPrimaryContainer,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: done ? null : theme.colorScheme.onPrimaryContainer,
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => WorkoutScreen(day: day)),
        ),
      ),
    );
  }
}

extension on SlotKind {
  IconData get icon => switch (this) {
    SlotKind.meal => Icons.restaurant_outlined,
    SlotKind.workout => Icons.fitness_center,
    SlotKind.sleep => Icons.bedtime_outlined,
    SlotKind.measurement => Icons.straighten,
    SlotKind.lab => Icons.biotech_outlined,
    SlotKind.other => Icons.schedule,
  };
}
