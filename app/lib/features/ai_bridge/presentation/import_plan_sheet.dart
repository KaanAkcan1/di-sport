import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/result/result.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/ai_bridge/domain/plan_validator.dart';
import 'package:disport/features/plan/application/plan_providers.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AI'ın verdiği planı içeri alma akışı — spec 7.3'ün dördüncü kapısı.
///
/// Yapıştır → doğrula → (hata varsa AI'a geri yapıştırılabilir mesaj) →
/// önizle → onayla. Doğrulamayı geçmeden hiçbir şey yazılmıyor.
class ImportPlanSheet extends ConsumerStatefulWidget {
  const ImportPlanSheet({super.key});

  @override
  ConsumerState<ImportPlanSheet> createState() => _ImportPlanSheetState();
}

class _ImportPlanSheetState extends ConsumerState<ImportPlanSheet> {
  final _controller = TextEditingController();

  String? _error;
  ValidatedPlan? _validated;
  final _acceptedNewIds = <String>{};
  var _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    setState(() => _busy = true);
    final validator = await ref.read(planValidatorProvider.future);
    final result = validator.validate(_controller.text);

    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (result) {
        case Ok(:final value):
          _validated = value;
          _error = null;
          // Yeni hareketler varsayılan olarak işaretli gelir: doğrulamayı
          // geçtiler ve kullanıcı zaten planı istiyor. Tek tek onaylatmak
          // gereksiz sürtünme olurdu; kaldırmak isteyen kaldırır.
          _acceptedNewIds
            ..clear()
            ..addAll(value.newExercises.map((e) => e.id));
        case Err(:final failure):
          _validated = null;
          _error = failure.message;
      }
    });
  }

  Future<void> _import() async {
    final validated = _validated;
    if (validated == null) return;

    setState(() => _busy = true);
    final result = await ref
        .read(planImporterProvider)
        .import(validated, acceptedNewExerciseIds: _acceptedNewIds);

    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case Ok(:final value):
        ref
          ..invalidate(activePlanProvider)
          ..invalidate(todayPlanDayProvider)
          ..invalidate(missedStreakProvider);

        final l10n = context.l10n;
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              value.addedExercises > 0
                  ? l10n.importPlanLoadedWithExercises(
                      value.dayCount,
                      value.addedExercises,
                    )
                  : l10n.importPlanLoaded(value.dayCount),
            ),
          ),
        );
      case Err(:final failure):
        setState(() => _error = failure.message);
    }
  }

  void _reset() {
    setState(() {
      _controller.clear();
      _validated = null;
      _error = null;
      _acceptedNewIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final validated = _validated;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(l10n.importPlanTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.importPlanDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          TextField(
            key: const Key('plan-json-field'),
            controller: _controller,
            maxLines: 6,
            minLines: 4,
            style: theme.textTheme.bodySmall,
            decoration: const InputDecoration(
              hintText: '{ "schemaVersion": 1, ... }',
            ),
            onChanged: (_) {
              // Metin değişince önceki sonuç geçersiz: eski önizlemeyle
              // yeni metni içeri almak veri karışıklığı olurdu.
              if (_validated != null || _error != null) {
                setState(() {
                  _validated = null;
                  _error = null;
                });
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _validate,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(l10n.importPlanValidate),
                ),
              ),
              if (_controller.text.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  onPressed: _busy ? null : _reset,
                  icon: const Icon(Icons.clear),
                  tooltip: l10n.commonClear,
                ),
              ],
            ],
          ),

          if (_error case final message?) ...[
            const SizedBox(height: AppSpacing.lg),
            _ErrorCard(message: message),
          ],

          if (validated != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _PreviewCard(
              validated: validated,
              acceptedIds: _acceptedNewIds,
              onToggle: (id, accepted) => setState(() {
                accepted ? _acceptedNewIds.add(id) : _acceptedNewIds.remove(id);
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _busy ? null : _import,
              icon: const Icon(Icons.download_done),
              label: Text(l10n.importPlanImport),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Doğrulama hatası — AI'a geri yapıştırılmak üzere kopyalanabilir.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final l10n = context.l10n;

    return Card(
      color: semantic.dangerSurface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: semantic.danger),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.importPlanFailedTitle,
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Doğrulayıcının mesajı **çevrilmez**: AI'a olduğu gibi geri
            // yapıştırılmak üzere yazıldı (spec 7.3).
            SelectableText(message, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.importPlanPasteBackHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: message));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.importPlanErrorCopied)),
                );
              },
              icon: const Icon(Icons.copy),
              label: Text(l10n.importPlanCopyError),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yazmadan önce ne geldiğini gösteren önizleme.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.validated,
    required this.acceptedIds,
    required this.onToggle,
  });

  final ValidatedPlan validated;
  final Set<String> acceptedIds;
  final void Function(String id, bool accepted) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final plan = validated.plan;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.meta.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.importPlanSummary(
                plan.meta.startDate,
                plan.meta.weeks,
                validated.dayCount,
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),

            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _Tag(
                  icon: Icons.fitness_center,
                  label: l10n.importPlanGym(validated.daysOfType('gym')),
                ),
                _Tag(
                  icon: Icons.home_outlined,
                  label: l10n.importPlanHome(validated.daysOfType('home')),
                ),
                _Tag(
                  icon: Icons.self_improvement,
                  label: l10n.importPlanRest(validated.daysOfType('rest')),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              l10n.importPlanGoals(
                '${plan.goals.dailyKcal}',
                '${plan.goals.proteinG}',
                '${plan.goals.waterL}',
                '${plan.goals.targetLossKg}',
              ),
              style: theme.textTheme.bodySmall,
            ),

            if (validated.newExercises.isNotEmpty) ...[
              const Divider(height: AppSpacing.xl2),
              Text(
                l10n.importPlanNewExercisesTitle,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                l10n.importPlanNewExercisesDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              for (final candidate in validated.newExercises)
                CheckboxListTile(
                  key: Key('accept-${candidate.id}'),
                  value: acceptedIds.contains(candidate.id),
                  onChanged: (value) =>
                      onToggle(candidate.id, value ?? false),
                  title: Text(candidate.displayName),
                  subtitle: Text(candidate.id),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 15),
    label: Text(label),
    visualDensity: VisualDensity.compact,
  );
}
