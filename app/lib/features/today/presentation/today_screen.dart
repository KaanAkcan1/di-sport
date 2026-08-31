import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/turkish_date.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/presentation/daily_flags_card.dart';
import 'package:disport/features/today/presentation/day_note_field.dart';
import 'package:disport/features/today/presentation/measurement_inputs.dart';
import 'package:disport/features/today/presentation/missed_streak_banner.dart';
import 'package:disport/features/today/presentation/slot_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Günlük ekran: günün özeti, zaman omurgası, kayıtlar.
///
/// Kâğıt çizelgenin bir gün sütununun karşılığı. Sıralama sabah
/// 05:45'e göre: önce bugünün özeti (bir bakışta durum), sonra omurga
/// (sırada ne var), sonra kayıt alanları.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planDay = ref.watch(todayPlanDayProvider);

    return AppAsyncView<FullPlanDay?>(
      value: planDay,
      onRetry: () => ref.invalidate(todayPlanDayProvider),
      data: (day) => AppScreenBody(
        children: [
          const _TodayBand(),
          const SizedBox(height: AppSpacing.xl2),
          const MissedStreakBanner(),

          if (day == null)
            const _NoPlanNotice()
          else ...[
            if (day.headline.isNotEmpty) _Headline(text: day.headline),
            _Rail(day: day),
            if (day.dinnerSuggestion.isNotEmpty)
              _DinnerHint(text: day.dinnerSuggestion),
          ],

          const SizedBox(height: AppSpacing.xl2),
          const MeasurementInputs(),
          const SizedBox(height: AppSpacing.xl2),
          const DailyFlagsCard(),
          const SizedBox(height: AppSpacing.xl2),
          const DayNoteField(),
        ],
      ),
    );
  }
}

/// Günün özeti — ekranın ağırlık merkezi.
class _TodayBand extends ConsumerWidget {
  const _TodayBand();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final log = ref.watch(todayLogProvider).value;
    final weight = ref.watch(todayWeightProvider).value;
    final day = ref.watch(todayPlanDayProvider).value;

    final checked = log?.checkedSlotIds.length ?? 0;
    final total = day?.slots.length ?? 0;

    return AppStatBand(
      title: TurkishDate.weekdayAndDay(now),
      subtitle: day?.type.label ?? 'Plan yok',
      // İki sayı, üç değil. Üçüncüsü kuralların sayacıydı ama o sayaç
      // hemen alttaki kartın başlığında da duruyor ve ikisi aynı
      // ekranda görünüyordu — özet olmaktan çıkıp tekrara dönüşmüştü.
      // İki sütun ayrıca rakamlara nefes veriyor.
      stats: [
        AppStat(
          caption: 'Kilo',
          value: weight,
          unit: MetricKinds.unitOf(MetricKinds.weight),
        ),
        AppStat(
          caption: 'Program',
          text: total == 0 ? '—' : '$checked/$total',
        ),
      ],
    );
  }
}

/// Rayı saate bağlar — dakikada bir yeniden çiziliyor.
class _Rail extends ConsumerWidget {
  const _Rail({required this.day});

  final FullPlanDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    return SlotList(day: day, now: now);
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DinnerHint extends StatelessWidget {
  const _DinnerHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.restaurant_outlined,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Akşam önerisi: $text',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Plan yokken gösterilen yönlendirme.
///
/// Tartı ve kutucuklar plan olmadan da çalışır — kullanıcı plan almadan
/// önce de kilosunu kaydedebilmeli. Bu yüzden ekranın tamamı değil,
/// yalnız omurga bölümü boş durum gösterir.
class _NoPlanNotice extends StatelessWidget {
  const _NoPlanNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.event_busy_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bugün için plan yok',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Plan sekmesinden bir program yükle. Tartı ve günün '
                    'kutucukları plan olmadan da çalışır.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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

extension on PlanDayType {
  String get label => switch (this) {
    PlanDayType.gym => 'Salon günü',
    PlanDayType.home => 'Ev antrenmanı',
    PlanDayType.rest => 'Dinlenme günü',
  };
}
