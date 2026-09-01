import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart';
import 'package:disport/features/nutrition/domain/activity.dart';
import 'package:disport/features/nutrition/presentation/food_labels.dart';
import 'package:disport/features/workout/domain/energy_estimator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Serbest aktivite kaydı: aktivite seç → süre gir → ≈kcal.
///
/// Üç adım tek sayfada duruyor çünkü tahmin **girerken** görünmeli.
/// Ayrı bir onay ekranına taşımak, kullanıcının süreyi değiştirip
/// sonucun nasıl değiştiğini görmesini engellerdi.
Future<void> showActivityLogSheet(
  BuildContext context, {
  required String isoDate,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _ActivitySheet(isoDate: isoDate),
);

class _ActivitySheet extends ConsumerStatefulWidget {
  const _ActivitySheet({required this.isoDate});

  final String isoDate;

  @override
  ConsumerState<_ActivitySheet> createState() => _ActivitySheetState();
}

class _ActivitySheetState extends ConsumerState<_ActivitySheet> {
  final _searchController = TextEditingController();
  String _query = '';
  Activity? _selected;
  int _minutes = 30;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weight = ref.watch(currentWeightKgProvider).value ?? 70;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: _selected == null
          ? _picker()
          : _detail(activity: _selected!, weightKg: weight),
    );
  }

  Widget _picker() {
    final results = ref.watch(activityCatalogProvider(_query));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.activityLogTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: context.l10n.activitySearchHint,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 280,
          child: AppAsyncView(
            value: results,
            emptyWhen: (list) => list.isEmpty,
            empty: AppEmptyState(
              icon: Icons.directions_run,
              title: context.l10n.activityEmptyTitle,
              description: context.l10n.activityEmptyMessage,
            ),
            data: (list) => ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(activityDisplayName(context, list[index])),
                trailing: Text('${list[index].met} MET'),
                onTap: () => setState(() => _selected = list[index]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detail({required Activity activity, required double weightKg}) {
    final kcal = kcalFor(
      met: activity.met,
      weightKg: weightKg,
      duration: Duration(minutes: _minutes),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => setState(() => _selected = null),
            ),
            Expanded(
              child: Text(
                activityDisplayName(context, activity),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Kaydırıcı, sayı alanı değil: süre bir tahmin ve kullanıcı
        // "kırk dakika kadar" diye düşünüyor. Beş dakikalık adım o
        // belirsizliğe uygun; dakika dakika girmek yanlış bir kesinlik
        // hissi verirdi.
        Text(context.l10n.activityMinutesLabel),
        Slider(
          value: _minutes.toDouble(),
          min: 5,
          max: 180,
          divisions: 35,
          label: '$_minutes',
          onChanged: (value) => setState(() => _minutes = value.round()),
        ),

        const SizedBox(height: AppSpacing.md),
        AppMetricStrip([
          AppMetric(
            caption: context.l10n.activityMinutesLabel,
            value: '$_minutes',
            unit: 'dk',
          ),
          AppMetric(
            caption: context.l10n.todayMetricBurned,
            value: '≈${kcal.round()}',
            unit: 'kcal',
          ),
        ]),
        const SizedBox(height: AppSpacing.xl),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await ref
                  .read(activitiesRepositoryProvider)
                  .logActivity(
                    activity: activity,
                    isoDate: widget.isoDate,
                    minutes: _minutes,
                    weightKg: weightKg,
                  );
              navigator.pop();
            },
            child: Text(context.l10n.activityAdd),
          ),
        ),
      ],
    );
  }
}
