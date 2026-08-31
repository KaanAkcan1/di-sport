import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/workout/presentation/workout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Günün zaman omurgası: öğünler, antrenman, uyku, ölçüm, tahlil.
///
/// Slotlar düz bir liste değil bir **raya** asılı; ray geçmişle geleceği
/// ayırıyor ve araya "şimdi" işareti giriyor. Gerekçe: sabah uygulamayı
/// açan kullanıcının tek sorusu "sırada ne var" ve düz listede bu bilgi
/// hiç yoktu.
///
/// Antrenman slotu diğerlerinden farklı: işaretlenmiyor, dokununca
/// Antrenman ekranını açıyor. Kutucuk oradaki setler tamamlandıkça
/// kendiliğinden doluyor.
class SlotList extends ConsumerWidget {
  const SlotList({super.key, required this.day, required this.now});

  final FullPlanDay day;

  /// Şu anki zaman. Dışarıdan alınıyor ki test sabit bir ana kilitlensin
  /// ve widget tiker'a bağımlı olmasın.
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(todayLogProvider).value;
    final iso = ref.watch(todayIsoProvider);

    final slots = [...day.slots]
      ..sort((a, b) => a.time.compareTo(b.time));
    final nowMinutes = now.hour * 60 + now.minute;

    // "Sıradaki" = saati henüz geçmemiş ilk slot. Bu slot rayda vurgulu
    // renk alıyor; kullanıcının aradığı satır o.
    final nextIndex = slots.indexWhere(
      (slot) => _minutesOf(slot.time) > nowMinutes,
    );

    final rows = <Widget>[];
    var markerDrawn = false;

    for (final (index, slot) in slots.indexed) {
      final past = _minutesOf(slot.time) <= nowMinutes;

      // "Şimdi" işareti geçmiş slotlarla gelecek slotlar arasına bir kez
      // giriyor. Gün başındaysa (hiç slot geçmemişse) hiç çizilmiyor —
      // listenin tepesinde asılı bir çizgi bilgi taşımaz.
      if (!past && !markerDrawn && index > 0) {
        rows.add(AppNowMarker(label: _formatNow()));
        markerDrawn = true;
      }

      final checked = log?.isSlotChecked(slot.id) ?? false;
      final workoutDone = log?.workoutDone ?? false;

      rows.add(
        AppTimeRailItem(
          time: slot.time,
          isFirst: index == 0,
          isLast: index == slots.length - 1,
          state: _stateFor(
            past: past,
            isNext: index == nextIndex,
            done: slot.kind == SlotKind.workout ? workoutDone : checked,
          ),
          onTap: slot.kind == SlotKind.workout
              ? () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WorkoutScreen(day: day),
                  ),
                )
              : () => ref.read(todayRepositoryProvider).toggleSlot(iso, slot.id),
          child: slot.kind == SlotKind.workout
              ? _WorkoutRow(day: day, slot: slot, done: workoutDone)
              : _SlotRow(slot: slot, checked: checked),
        ),
      );
    }

    // Bütün slotlar geçmişse işaret en sona giriyor: gün bitti bilgisi.
    if (!markerDrawn && slots.isNotEmpty && nextIndex == -1) {
      rows.add(AppNowMarker(label: _formatNow()));
    }

    return Column(children: rows);
  }

  String _formatNow() =>
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}';

  static RailNodeState _stateFor({
    required bool past,
    required bool isNext,
    required bool done,
  }) {
    if (done) return RailNodeState.done;
    if (isNext) return RailNodeState.next;
    return past ? RailNodeState.missed : RailNodeState.upcoming;
  }

  /// `HH:mm` → gün içi dakika. Bozuk biçim günün sonuna atılıyor ki
  /// sıralamayı bozmasın.
  static int _minutesOf(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 24 * 60;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return 24 * 60;
    return hour * 60 + minute;
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.slot, required this.checked});

  final PlanSlot slot;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Kutucuk yerine daire: rayın düğümü gibi okunuyor ve
        // işaretlenince markanın yeşiliyle doluyor.
        _CheckDot(checked: checked),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            slot.label,
            style: theme.textTheme.bodyLarge?.copyWith(
              // İşaretlenen öğün üstü çizili: tamamlananla kalanı bir
              // bakışta ayırmak renkten bağımsız olarak da işe yarar
              // (ui-ux §1 `color-not-only`).
              decoration: checked ? TextDecoration.lineThrough : null,
              color: checked ? theme.colorScheme.onSurfaceVariant : null,
            ),
          ),
        ),
        Icon(
          slot.kind.icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

/// Rayın düğümü — dokunulabilir işaret.
class _CheckDot extends StatelessWidget {
  const _CheckDot({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      checked: checked,
      label: checked ? 'işaretli' : 'işaretsiz',
      child: AnimatedContainer(
        duration: AppMotion.respectingMotion(context, AppMotion.fast),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: checked ? theme.colorScheme.primary : Colors.transparent,
          border: Border.all(
            color: checked
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: AppBorder.emphasis,
          ),
        ),
        child: checked
            ? Icon(
                Icons.check,
                size: 14,
                color: theme.colorScheme.onPrimary,
              )
            : null,
      ),
    );
  }
}

/// Antrenman satırı — rayın en ağır düğümü.
class _WorkoutRow extends StatelessWidget {
  const _WorkoutRow({
    required this.day,
    required this.slot,
    required this.done,
  });

  final FullPlanDay day;
  final PlanSlot slot;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: done
            ? theme.colorScheme.surfaceContainer
            : theme.colorScheme.primaryContainer,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.fitness_center,
            size: 20,
            color: done
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: done ? null : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  '${day.exercises.length} hareket',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: done
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: done
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onPrimaryContainer,
          ),
        ],
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
