import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/catalog/presentation/display_name.dart';
import 'package:disport/features/catalog/presentation/exercise_detail_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bir hareketin tam anlatımı.
///
/// Detay dört sekmeye bölünmüş: antrenman sırasında kimse tek sayfada on
/// paragraf okumaz, ama katalogda gezerken bilginin tamamı erişilebilir
/// olmalı (spec Bölüm 6, katmanlı detay).
///
/// Görsel, katlanan bir başlık yerine "Adımlar" sekmesinin içinde duruyor.
/// Katlanan başlık denendi ve iki sorun çıkardı: rozetler sekme çubuğuna
/// biniyordu, sekme etiketleri koyu fotoğrafın üstünde okunmuyordu. Her
/// ikisi de perde ve koşullu renkle örtülebilirdi, ama çubuk tamamen
/// toplandığında beyaz etiketin beyaz zeminde kalması gibi yeni kenar
/// durumları doğuruyordu. Görsel içeriğin içinde olunca bu sınıf hata
/// tümden ortadan kalkıyor ve metne daha çok yer kalıyor.
class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = ref.watch(exerciseByIdProvider(exerciseId));

    return AppAsyncView<Exercise?>(
      value: exercise,
      loading: const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      emptyWhen: (value) => value == null,
      empty: Scaffold(
        appBar: AppBar(),
        body: AppEmptyState(
          icon: Icons.help_outline,
          title: context.l10n.catalogExerciseNotFound,
          description: context.l10n.catalogExerciseNotFoundDescription,
        ),
      ),
      error: (error) => Scaffold(
        appBar: AppBar(),
        body: AppEmptyState(
          icon: Icons.error_outline,
          tone: AppEmptyStateTone.danger,
          title: context.l10n.catalogExerciseLoadError,
          description: '$error',
          actionLabel: context.l10n.commonRetry,
          onAction: () => ref.invalidate(exerciseByIdProvider(exerciseId)),
        ),
      ),
      data: (value) => _Content(exercise: value!),
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
      child: Scaffold(
        appBar: AppBar(
          title: Text(exerciseDisplayName(context, exercise)),
          // Etiketlerin varsayılan yatay dolgusu dört Türkçe kelimeyi
          // taşırıyor; "Varyantlar" son harfinden kırpılıyordu.
          bottom: TabBar(
            labelPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
            ),
            tabs: [
              // Kısa etiketler: spec'teki uzun biçimler ("Nasıl yapılır",
              // "Kolaylaştır / Zorlaştır") telefon genişliğine sığmıyor ve
              // kaydırmalı çubukta son iki sekme ekran dışında kalıyordu.
              // Keşfedilebilirlik kelime zenginliğinden önce gelir.
              Tab(text: context.l10n.catalogTabSteps),
              Tab(text: context.l10n.catalogTabMistakes),
              Tab(text: context.l10n.catalogTabVariants),
              Tab(text: context.l10n.catalogTabSafety),
            ],
          ),
        ),
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
