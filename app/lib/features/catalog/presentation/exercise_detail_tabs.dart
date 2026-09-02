import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/catalog/domain/restriction_match.dart';
import 'package:disport/features/catalog/presentation/exercise_detail_screen.dart';
import 'package:disport/features/catalog/presentation/exercise_visuals.dart';
import 'package:disport/features/medical/application/medical_providers.dart';
import 'package:disport/features/medical/domain/medical_fact.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Detay sayfasının dört sekmesi.
///
/// Ayrı dosyada tutuluyorlar: dördü de ekran dosyasına konsaydı o dosya
/// dört yüz satırı geçer ve tek bir sekmeyi değiştirmek diğer üçünü de
/// okumayı gerektirirdi.

const _tabPadding = EdgeInsets.fromLTRB(
  AppSpacing.screenH,
  AppSpacing.lg,
  AppSpacing.screenH,
  AppSpacing.xl4,
);

/// Sekme 1: özet, başlangıç, adımlar, nefes/tempo/güvenlik satırları.
///
/// İçerik `contentFor(locale)` ile çözülür (v3 §6.5): dilin kendi
/// içeriği varsa o, yoksa öteki dil. Güvenlik satırı kullanıcının
/// kimlikli hareket kısıtıyla eşleşiyorsa amber vurgulanır.
class HowToTab extends ConsumerWidget {
  const HowToTab({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final semantic = context.semantic;
    final content = exercise.contentFor(
      Localizations.localeOf(context).languageCode,
    );
    final restrictions =
        ref.watch(medicalFactsProvider).value ?? const <MedicalFact>[];
    final restricted = matchingRestrictions(exercise, [
      for (final fact in restrictions)
        if ((fact.kind == MedicalFactKind.restriction ||
                fact.kind == MedicalFactKind.diagnosis) &&
            fact.conditionId != null)
          fact.conditionId!,
    ]).isNotEmpty;

    return ListView(
      padding: _tabPadding,
      children: [
        if (exercise.hasImage) ...[
          _HeaderImage(exercise: exercise),
          const SizedBox(height: AppSpacing.lg),
        ],

        Row(
          children: [
            Chip(
              avatar: Icon(exercise.category.icon, size: 16),
              label: Text(exercise.category.label(context)),
            ),
            const SizedBox(width: AppSpacing.sm),
            ExerciseLocationBadge(location: exercise.location),
            const Spacer(),
            ExerciseDifficultyBar(level: exercise.difficulty),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        if (content.summary case final summary?) ...[
          Text(summary, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.xl2),
        ],

        if (content.cues.isNotEmpty) ...[
          AppSection(
            title: l10n.catalogCuesTitle,
            description: l10n.catalogCuesDescription,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final cue in content.cues) Chip(label: Text(cue)),
              ],
            ),
          ),
        ],

        if (content.setup.isNotEmpty)
          AppSection(
            title: l10n.catalogSetupTitle,
            child: _BulletList(items: content.setup),
          ),

        if (content.execution.isNotEmpty)
          AppSection(
            title: l10n.catalogExecutionTitle,
            child: _NumberedList(items: content.execution),
          ),

        // Boş alan hiç çizilmiyor: boş bir başlık kullanıcıya "burada
        // bir şey olmalıydı" dedirtir.
        if (content.breathing != null ||
            content.tempo != null ||
            content.safety != null)
          AppSection(
            title: l10n.catalogBreathingTempoTitle,
            child: Column(
              children: [
                if (content.breathing case final breathing?) ...[
                  _LabeledRow(
                    icon: Icons.air,
                    label: l10n.catalogBreathingLabel,
                    value: breathing,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (content.tempo case final tempo?) ...[
                  _LabeledRow(
                    icon: Icons.timer_outlined,
                    label: l10n.catalogTempoLabel,
                    value: tempo,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (content.safety case final safety?)
                  // Kısıt eşleşmesinde amber: renk + ikon + metin
                  // birlikte (renk tek başına anlam taşımaz).
                  _LabeledRow(
                    icon: restricted
                        ? Icons.warning_amber_outlined
                        : Icons.shield_outlined,
                    label: restricted
                        ? l10n.catalogSafetyRestricted
                        : l10n.catalogSafetyLabel,
                    value: safety,
                    color: restricted ? semantic.warning : null,
                  ),
              ],
            ),
          ),

        _MetaSection(exercise: exercise),
      ],
    );
  }
}

/// Sekme 2: sık hatalar — hata, nedeni, düzeltmesi.
class MistakesTab extends StatelessWidget {
  const MistakesTab({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final content = exercise.contentFor(
      Localizations.localeOf(context).languageCode,
    );
    if (content.commonMistakes.isEmpty) {
      return AppEmptyState(title: context.l10n.catalogNoMistakes);
    }

    final theme = Theme.of(context);
    final semantic = context.semantic;

    return ListView.separated(
      padding: _tabPadding,
      itemCount: content.commonMistakes.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final mistake = content.commonMistakes[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.close, size: 18, color: semantic.danger),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        mistake.mistake,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _MistakeLine(
                  label: context.l10n.catalogMistakeWhy,
                  value: mistake.why,
                ),
                const SizedBox(height: AppSpacing.sm),
                _MistakeLine(
                  label: context.l10n.catalogMistakeFix,
                  value: mistake.fix,
                  emphasize: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Sekme 3: kolaylaştırma ve zorlaştırma zinciri.
class VariantsTab extends ConsumerWidget {
  const VariantsTab({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = [...exercise.regressions, ...exercise.progressions];

    if (ids.isEmpty) {
      return AppEmptyState(
        icon: Icons.linear_scale,
        title: context.l10n.catalogNoVariants,
        description: context.l10n.catalogNoVariantsDescription,
      );
    }

    final resolved = ref.watch(exerciseVariantsProvider(exercise.id));

    return AppAsyncView<Map<String, Exercise>>(
      value: resolved,
      onRetry: () => ref.invalidate(exerciseVariantsProvider(exercise.id)),
      data: (byId) => ListView(
        padding: _tabPadding,
        children: [
          AppSection(
            title: context.l10n.catalogRegressionsTitle,
            description: context.l10n.catalogRegressionsDescription,
            child: _VariantList(
              ids: exercise.regressions,
              byId: byId,
              icon: Icons.arrow_downward,
            ),
          ),
          AppSection(
            title: context.l10n.catalogProgressionsTitle,
            description: context.l10n.catalogProgressionsDescription,
            child: _VariantList(
              ids: exercise.progressions,
              byId: byId,
              icon: Icons.arrow_upward,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sekme 4: güvenlik notu.
class SafetyTab extends StatelessWidget {
  const SafetyTab({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;

    return ListView(
      padding: _tabPadding,
      children: [
        Card(
          color: semantic.warningSurface,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: semantic.warning),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    exercise
                            .contentFor(
                              Localizations.localeOf(context).languageCode,
                            )
                            .safety ??
                        context.l10n.catalogSafetyDisclaimer,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl2),
        Text(
          context.l10n.catalogSafetyDisclaimer,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Ortak parçalar
// ---------------------------------------------------------------------

/// Başlangıç ve bitiş karesini yan yana gösteren görsel.
class _HeaderImage extends StatelessWidget {
  const _HeaderImage({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.catalogImageSemantics(exercise.displayNameTr),
      image: true,
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: AspectRatio(
          // Görseller iki kare yan yana üretiliyor; oran kaynakta sabit.
          aspectRatio: 900 / 368,
          child: Image.asset(
            exercise.imagePath!,
            fit: BoxFit.cover,
            errorBuilder: (context, _, _) => ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
          ),
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(item, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

class _NumberedList extends StatelessWidget {
  const _NumberedList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, item) in items.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primaryContainer,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(item, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

class _LabeledRow extends StatelessWidget {
  const _LabeledRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Verilirse ikon ve etiket bu tonda — kısıt eşleşmesinin amber
  /// vurgusu. Metin normal kalır: uyarı okunurluğu bozmamalı.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: color == null ? null : FontWeight.w600,
                ),
              ),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _MistakeLine extends StatelessWidget {
  const _MistakeLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: emphasize
                ? context.semantic.success
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _VariantList extends StatelessWidget {
  const _VariantList({
    required this.ids,
    required this.byId,
    required this.icon,
  });

  final List<String> ids;
  final Map<String, Exercise> byId;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      children: [
        for (final id in ids)
          if (byId[id] case final exercise?)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: Icon(icon),
                title: Text(exercise.displayNameTr),
                subtitle: Text(
                  context.l10n.catalogDifficultyOutOfFive(exercise.difficulty),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    // pushReplacement: zincirde gezinirken geri yığını
                    // şişmesin — kullanıcı beş varyant gezip beş kez geri
                    // tuşuna basmak zorunda kalmamalı.
                    builder: (_) =>
                        ExerciseDetailScreen(exerciseId: exercise.id),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _MetaSection extends StatelessWidget {
  const _MetaSection({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return AppSection(
      title: context.l10n.catalogMetaTitle,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _LabeledRow(
            icon: Icons.sports_gymnastics,
            label: context.l10n.catalogTargetMuscles,
            value: [
              ...exercise.primaryMuscles,
              ...exercise.secondaryMuscles,
            ].join(', '),
          ),
          const SizedBox(height: AppSpacing.md),
          _LabeledRow(
            icon: Icons.handyman_outlined,
            label: context.l10n.catalogEquipmentLabel,
            value: exercise.equipment.join(', '),
          ),
        ],
      ),
    );
  }
}
