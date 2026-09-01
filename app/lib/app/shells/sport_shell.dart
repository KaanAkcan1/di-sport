import 'package:disport/app/shells/shell_header.dart';
import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_date.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/catalog/presentation/catalog_screen.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart'
    show energySourceProvider;
import 'package:disport/features/plan/presentation/plan_screen.dart';
import 'package:disport/features/today/application/today_providers.dart'
    show todayIsoProvider, todayPlanDayProvider;
import 'package:disport/features/workout/application/workout_providers.dart';
import 'package:disport/features/workout/presentation/planned_vs_done_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Spor sekmesi: PLAN · ANTRENMAN · KATALOG.
///
/// Plan düzenlemek ile antrenman yapmak ayrı yerler (Hevy ayrımı):
/// birini yaparken ötekinin düğmelerini görmek dikkat dağıtıyordu.
class SportShell extends StatelessWidget {
  const SportShell({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppSegmentedShell(
      header: ShellHeader(title: l10n.tabSport),
      labels: [l10n.sportTabPlan, l10n.sportTabWorkout, l10n.sportTabCatalog],
      children: const [PlanScreen(), _WorkoutTab(), CatalogScreen()],
    );
  }
}

/// Antrenman sekmesi (v3 §6.3): bugünün girişi + geçmiş seans listesi.
class _WorkoutTab extends ConsumerWidget {
  const _WorkoutTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final todayIso = ref.watch(todayIsoProvider);
    final todayPlan = ref.watch(todayPlanDayProvider).value;
    final history =
        ref.watch(workoutHistoryDaysProvider).value ??
        const <({String date, Duration total, int exerciseCount})>[];
    final burned = history.isEmpty
        ? const <String, double>{}
        : ref.watch(_burnedRangeProvider((
                  history.last.date,
                  history.first.date,
                ))).value ??
              const <String, double>{};

    if (todayPlan?.hasWorkout != true && history.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.fitness_center_outlined,
          title: l10n.sportWorkoutEmptyTitle,
          description: l10n.sportWorkoutEmptyMessage,
        ),
      );
    }

    return AppScreenBody(
      children: [
        if (todayPlan?.hasWorkout ?? false) ...[
          AppSpotCard(
            key: const Key('workout-today-card'),
            eyebrow: l10n.sportWorkoutTodayTitle,
            leading: LucideIcons.dumbbell,
            title: l10n.plannedVsDoneTitle,
            subtitle: todayPlan!.headline.isEmpty
                ? l10n.sportWorkoutTodayBody
                : todayPlan.headline,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlannedVsDoneScreen(dateKey: todayIso),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (history.isNotEmpty) ...[
          AppSectionLabel(
            l10n.sportWorkoutHistory,
            trailing: Text('${history.length}'),
          ),
          for (final day in history)
            ListTile(
              key: Key('workout-history-${day.date}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const AppIconTile(
                icon: LucideIcons.dumbbell,
                area: AppArea.sport,
                small: true,
              ),
              title: Text(
                TurkishDate.weekdayAndDay(DateTime.parse(day.date)),
              ),
              subtitle: Text(
                [
                  if (day.total > Duration.zero)
                    l10n.plannedVsDoneMinutes(day.total.inMinutes),
                  l10n.sportWorkoutExerciseCount(day.exerciseCount),
                  if ((burned[day.date] ?? 0) > 0)
                    // Enerji tahmini her yerde ≈ ile — kesinlik vaadi yok.
                    '≈${burned[day.date]!.round()} kcal',
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PlannedVsDoneScreen(dateKey: day.date),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Aralığın ≈kcal değerleri — `EnergySource` portu üzerinden.
final _burnedRangeProvider = StreamProvider.autoDispose
    .family<Map<String, double>, (String, String)>((ref, range) async* {
      final source = await ref.watch(energySourceProvider.future);
      yield* source.burnedBetween(range.$1, range.$2);
    });
