import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_date.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/ai_bridge/presentation/import_plan_sheet.dart';
import 'package:disport/features/plan/application/plan_providers.dart';
import 'package:disport/features/plan/data/sample_plan.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/plan/presentation/plan_calendar.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:disport/features/workout/presentation/workout_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// 28 günlük programın takvim görünümü ve AI eylemleri.
///
/// Eylemler plan olsa da olmasa da üstte duruyor: kullanıcı her an yeni
/// plan isteyebilmeli, eskisini beklemek zorunda kalmamalı.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(activePlanProvider);

    return Column(
      children: [
        const PlanActions(),
        Expanded(
          child: AppAsyncView<FullPlan?>(
            value: plan,
            emptyWhen: (value) => value == null,
            empty: _EmptyPlan(onLoadSample: () => _loadSample(ref)),
            onRetry: () => ref.invalidate(activePlanProvider),
            data: (value) => _PlanOverview(plan: value!),
          ),
        ),
      ],
    );
  }

  Future<void> _loadSample(WidgetRef ref) async {
    // Plan bugünden başlasın: kullanıcı "yükle" deyip Bugün sekmesine
    // geçtiğinde boş ekranla karşılaşmamalı.
    final today = DateTime.parse(ref.read(todayIsoProvider));
    await ref.read(planRepositoryProvider).insertFullPlan(
      buildSamplePlan(today),
    );
    ref
      ..invalidate(activePlanProvider)
      ..invalidate(missedStreakProvider);
  }
}

class _EmptyPlan extends StatelessWidget {
  const _EmptyPlan({required this.onLoadSample});

  final VoidCallback onLoadSample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.planEmptyTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.planEmptyBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: AppSpacing.xl),
              TextButton(
                onPressed: onLoadSample,
                child: Text(context.l10n.planLoadSample),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Plan sekmesinin üstündeki iki eylem.
///
/// Uygulamanın AI ile tek temas noktası burası: bağlam üret, dönen planı
/// içeri al. Uygulama hangi AI'ın kullanıldığını bilmez.
class PlanActions extends ConsumerStatefulWidget {
  const PlanActions({super.key});

  @override
  ConsumerState<PlanActions> createState() => _PlanActionsState();
}

class _PlanActionsState extends ConsumerState<PlanActions> {
  var _busy = false;

  Future<void> _requestPlan() async {
    setState(() => _busy = true);
    try {
      final markdown = await ref
          .read(contextMdBuilderProvider)
          .build(today: DateTime.now());

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          text: markdown,
          subject: context.l10n.planShareSubject,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openImport() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.92,
        child: ImportPlanSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              key: const Key('request-plan-button'),
              onPressed: _busy ? null : _requestPlan,
              icon: const Icon(Icons.auto_awesome),
              label: Text(context.l10n.planRequestButton),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('import-plan-button'),
              onPressed: _busy ? null : _openImport,
              icon: const Icon(Icons.file_download_outlined),
              label: Text(context.l10n.planImportButton),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanOverview extends ConsumerWidget {
  const _PlanOverview({required this.plan});

  final FullPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final todayIso = ref.watch(todayIsoProvider);
    final today = DateTime.parse(todayIso);
    final logs = ref.watch(planRangeLogsProvider).value ?? const {};

    return AppScreenBody(
      children: [
        Text(plan.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_formatDate(plan.startDate)} – ${_formatDate(plan.endDate)} · '
          '${context.l10n.planDayCount(plan.days.length)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        _GoalsCard(goals: plan.goals),
        const SizedBox(height: AppSpacing.xl2),

        for (var week = 1; week <= plan.weeks; week++)
          _WeekSection(
            plan: plan,
            weekIndex: week,
            today: today,
            logs: logs,
          ),

        const _CalendarLegend(),
        const SizedBox(height: AppSpacing.lg),
        _RulesCard(rules: plan.rules),
      ],
    );
  }

  static String _formatDate(DateTime date) => TurkishDate.dayMonth(date);
}

/// Takvim göstergesi — renk tek başına anlam taşımaz kuralının parçası.
class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;

    Widget item(Color color, String label, {bool outlined = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(2),
            border: outlined ? Border.all(color: color) : null,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.xs,
        children: [
          item(semantic.successSurface, context.l10n.planLegendDone),
          item(
            theme.colorScheme.surfaceContainerHigh,
            context.l10n.planLegendPartial,
          ),
          item(
            theme.colorScheme.outlineVariant,
            context.l10n.planLegendFree,
            outlined: true,
          ),
          item(
            theme.colorScheme.primary,
            context.l10n.planLegendWorkout,
            outlined: true,
          ),
        ],
      ),
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({required this.goals});

  final PlanGoals goals;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Wrap(
          spacing: AppSpacing.xl2,
          runSpacing: AppSpacing.lg,
          children: [
            _Goal(
              label: context.l10n.planGoalDaily,
              value: goals.dailyKcal,
              unit: 'kcal',
              digits: 0,
            ),
            _Goal(
              label: context.l10n.planGoalProtein,
              value: goals.proteinG,
              unit: 'g',
              digits: 0,
            ),
            _Goal(
              label: context.l10n.planGoalWater,
              value: goals.waterL,
              unit: 'L',
              digits: 0,
            ),
            _Goal(
              label: context.l10n.planGoalTarget,
              value: -goals.targetLossKg,
              unit: 'kg',
              digits: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _Goal extends StatelessWidget {
  const _Goal({
    required this.label,
    required this.value,
    required this.unit,
    required this.digits,
  });

  final String label;
  final num value;
  final String unit;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        AppMetricValue(
          value: value,
          unit: unit,
          fractionDigits: digits,
          size: AppMetricSize.medium,
        ),
      ],
    );
  }
}

class _WeekSection extends StatelessWidget {
  const _WeekSection({
    required this.plan,
    required this.weekIndex,
    required this.today,
    required this.logs,
  });

  final FullPlan plan;
  final int weekIndex;
  final DateTime today;
  final Map<String, DailyLogView> logs;

  @override
  Widget build(BuildContext context) {
    final days = plan.days.where((d) => d.weekIndex == weekIndex).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (days.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionLabel(
            context.l10n.planWeekLabel(weekIndex),
            trailing: days.first.headline.isEmpty
                ? null
                : Flexible(
                    child: Text(
                      days.first.headline,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
          ),
          PlanWeekGrid(
            days: days,
            logs: logs,
            today: today,
            onDayTap: (day) => day.exercises.isEmpty
                ? null
                : Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => WorkoutScreen(day: day),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({required this.rules});

  final PlanRules rules;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;

    return AppSection(
      title: context.l10n.planNutritionRules,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _RuleList(
            title: context.l10n.planRulesForbidden,
            items: rules.forbidden,
            color: semantic.danger,
            icon: Icons.close,
          ),
          const SizedBox(height: AppSpacing.md),
          _RuleList(
            title: context.l10n.planRulesFree,
            items: rules.free,
            color: semantic.success,
            icon: Icons.check,
          ),
        ],
      ),
    );
  }
}

class _RuleList extends StatelessWidget {
  const _RuleList({
    required this.title,
    required this.items,
    required this.color,
    required this.icon,
  });

  final String title;
  final List<String> items;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 15, color: color),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(item, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
