import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/catalog/presentation/exercise_detail_tabs.dart';
import 'package:disport/features/catalog/presentation/exercise_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bir hareketin tam anlatımı.
///
/// Detay dört sekmeye bölünmüş: antrenman sırasında kimse tek sayfada
/// on paragraf okumaz, ama katalogda gezerken bilginin tamamı erişilebilir
/// olmalı (spec Bölüm 6, katmanlı detay).
class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = ref.watch(exerciseByIdProvider(exerciseId));

    return Scaffold(
      body: AppAsyncView<Exercise?>(
        value: exercise,
        emptyWhen: (value) => value == null,
        empty: const AppEmptyState(
          icon: Icons.help_outline,
          title: 'Hareket bulunamadı',
          description: 'Bu hareket katalogdan kaldırılmış olabilir.',
        ),
        onRetry: () => ref.invalidate(exerciseByIdProvider(exerciseId)),
        data: (value) => _Content(exercise: value!),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: exercise.hasImage ? 240 : null,
            flexibleSpace: exercise.hasImage
                ? FlexibleSpaceBar(
                    background: _HeaderImage(exercise: exercise),
                  )
                : null,
            title: Text(exercise.nameTr),
            // Sabit genişlikte dört sekme, kaydırmasız.
            //
            // Spec'teki uzun etiketler ("Nasıl yapılır", "Kolaylaştır /
            // Zorlaştır") telefon genişliğine sığmıyor ve kaydırmalı
            // çubukta son iki sekme ekran dışında kalıyordu: kullanıcı
            // güvenlik notunun varlığını göremiyor. Kısa etiketler dördünü
            // birden görünür kılıyor — keşfedilebilirlik, kelime
            // zenginliğinden önce gelir.
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Adımlar'),
                Tab(text: 'Hatalar'),
                Tab(text: 'Varyantlar'),
                Tab(text: 'Güvenlik'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          children: [
            HowToTab(exercise: exercise),
            MistakesTab(exercise: exercise),
            VariantsTab(exercise: exercise),
            SafetyTab(exercise: exercise),
          ],
        ),
      ),
    );
  }
}

class _HeaderImage extends StatelessWidget {
  const _HeaderImage({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          exercise.imagePath!,
          fit: BoxFit.cover,
          errorBuilder: (context, _, _) =>
              ColoredBox(color: Theme.of(context).colorScheme.surfaceContainer),
        ),
        // Başlık metninin görsel üstünde okunur kalması için alttan
        // koyulaşan geçiş (ui-ux: metin kontrastı 4.5:1).
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0x99000000)],
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.md,
          child: Row(
            children: [
              _OnImageChip(
                icon: exercise.category.icon,
                label: exercise.category.labelTr,
              ),
              const SizedBox(width: AppSpacing.sm),
              _OnImageChip(
                icon: Icons.equalizer,
                label: 'Zorluk ${exercise.difficulty}/5',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnImageChip extends StatelessWidget {
  const _OnImageChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: Color(0xB3000000),
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
