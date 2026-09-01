import 'package:disport/app/shells/shell_header.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/catalog/presentation/catalog_screen.dart';
import 'package:disport/features/plan/presentation/plan_screen.dart';
import 'package:flutter/material.dart';

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

/// Antrenman geçmişi — M13 iskeleti; M16 seans listesiyle doldurur.
class _WorkoutTab extends StatelessWidget {
  const _WorkoutTab();

  @override
  Widget build(BuildContext context) => Center(
    child: AppEmptyState(
      icon: Icons.fitness_center_outlined,
      title: context.l10n.sportWorkoutEmptyTitle,
      description: context.l10n.sportWorkoutEmptyMessage,
    ),
  );
}
