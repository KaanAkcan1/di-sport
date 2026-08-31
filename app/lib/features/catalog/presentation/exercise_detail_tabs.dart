import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/catalog/presentation/exercise_detail_screen.dart';
import 'package:disport/features/catalog/presentation/exercise_visuals.dart';
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

/// Sekme 1: özet, başlangıç, adımlar, nefes ve tempo.
class HowToTab extends StatelessWidget {
  const HowToTab({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              label: Text(exercise.category.labelTr),
            ),
            const SizedBox(width: AppSpacing.sm),
            ExerciseLocationBadge(location: exercise.location),
            const Spacer(),
            ExerciseDifficultyBar(level: exercise.difficulty),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(exercise.summary, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.xl2),

        if (exercise.cues.isNotEmpty) ...[
          AppSection(
            title: 'Aklında tut',
            description: 'Antrenman sırasında bunlara bak.',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final cue in exercise.cues) Chip(label: Text(cue)),
              ],
            ),
          ),
        ],

        AppSection(
          title: 'Başlangıç',
          child: _BulletList(items: exercise.setup),
        ),

        AppSection(
          title: 'Hareket',
          child: _NumberedList(items: exercise.execution),
        ),

        AppSection(
          title: 'Nefes ve tempo',
          child: Column(
            children: [
              _LabeledRow(
                icon: Icons.air,
                label: 'Nefes',
                value: exercise.breathing,
              ),
              const SizedBox(height: AppSpacing.md),
              _LabeledRow(
                icon: Icons.timer_outlined,
                label: 'Tempo',
                value: exercise.tempo,
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
    if (exercise.commonMistakes.isEmpty) {
      return const AppEmptyState(title: 'Kayıtlı hata yok');
    }

    final theme = Theme.of(context);
    final semantic = context.semantic;

    return ListView.separated(
      padding: _tabPadding,
      itemCount: exercise.commonMistakes.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final mistake = exercise.commonMistakes[index];
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
                _MistakeLine(label: 'Neden sorun', value: mistake.why),
                const SizedBox(height: AppSpacing.sm),
                _MistakeLine(
                  label: 'Düzeltmesi',
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
      return const AppEmptyState(
        icon: Icons.linear_scale,
        title: 'Varyant tanımlı değil',
        description: 'Bu hareketin kolay ya da zor bir sürümü kayıtlı değil.',
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
            title: 'Kolaylaştır',
            description: 'Zorlanıyorsan buradan başla.',
            child: _VariantList(
              ids: exercise.regressions,
              byId: byId,
              icon: Icons.arrow_downward,
            ),
          ),
          AppSection(
            title: 'Zorlaştır',
            description: 'Kolay gelmeye başladığında sıradaki basamak.',
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
                    exercise.safety,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl2),
        Text(
          'Bu bilgiler genel niteliktedir ve hekim ya da fizyoterapist '
          'değerlendirmesinin yerine geçmez. Ağrı hissettiğinde hareketi '
          'bırak.',
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
      label:
          '${exercise.nameTr} hareketinin başlangıç ve bitiş pozisyonu',
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
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
                title: Text(exercise.nameTr),
                subtitle: Text('Zorluk ${exercise.difficulty}/5'),
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
      title: 'Künye',
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _LabeledRow(
            icon: Icons.sports_gymnastics,
            label: 'Hedef kaslar',
            value: [
              ...exercise.primaryMuscles,
              ...exercise.secondaryMuscles,
            ].join(', '),
          ),
          const SizedBox(height: AppSpacing.md),
          _LabeledRow(
            icon: Icons.handyman_outlined,
            label: 'Ekipman',
            value: exercise.equipment.join(', '),
          ),
        ],
      ),
    );
  }
}
