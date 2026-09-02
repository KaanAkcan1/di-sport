import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart';
import 'package:disport/features/nutrition/presentation/food_picker_screen.dart';
import 'package:disport/features/nutrition/presentation/water_row.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/plan/domain/meal_kind.dart';
import 'package:disport/features/plan/presentation/slot_editor_sheet.dart';
import 'package:disport/features/supplements/application/supplement_providers.dart';
import 'package:disport/features/today/application/day_providers.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/domain/day_flow.dart';
import 'package:disport/features/today/presentation/daily_flags_card.dart';
import 'package:disport/features/today/presentation/day_note_field.dart';
import 'package:disport/features/today/presentation/measurement_inputs.dart';
import 'package:disport/features/workout/presentation/planned_vs_done_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// GÜNÜN AKIŞI — Ana Sayfa'nın üçüncü ve son bölümü (v3).
///
/// Plan slotları, ilaç dozları ve tartı tek zaman çizgisinde. Varsayılan
/// görünüm ilk beş satır; "tamamı" gerisini **ve** eski ekranın ölçüm /
/// kural / not bölümlerini açıyor. v2'nin beş ayrı kartı akış satırına
/// indi — kullanıcı gününü görmek için beş listeyi kaydırmıyor.
///
/// Her satır dokunulabilir: öğün kaydını, doz işaretini, tartı girişini
/// satırın kendisi açıyor.
class DayFlowSection extends ConsumerStatefulWidget {
  const DayFlowSection({super.key, required this.day, this.readOnly = false});

  final FullPlanDay? day;

  /// Gelecek gün: plan görünür ("yarın ne var" meşru) ama hiçbir satır
  /// kayıt almaz — alan bırakmak yanlış güne kayıt yapmaya davet ederdi.
  final bool readOnly;

  @override
  ConsumerState<DayFlowSection> createState() => _DayFlowSectionState();
}

class _DayFlowSectionState extends ConsumerState<DayFlowSection> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(viewedDateProvider);
    final isToday = ref.watch(dayPositionProvider(date)) == DayPosition.today;
    final doses = ref.watch(todayDosesProvider);
    final log = ref.watch(dayLogProvider(date)).value;
    final weight = ref.watch(dayWeightProvider(date)).value;
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    // Öğün "yapıldı"sı kayıttır (mockup B1): o öğüne girilmiş kalemler
    // toplanıp satıra "486 kcal" olarak yazılır.
    final meals = ref.watch(dayMealsProvider(date)).value ?? const [];
    final kcalByKind = <MealKind, double>{};
    for (final entry in meals) {
      kcalByKind[entry.mealKind] =
          (kcalByKind[entry.mealKind] ?? 0) + entry.kcal;
    }

    final rows = buildDayFlow(
      slots: widget.day?.slots ?? const [],
      // Dozlar yalnız bugün akıtılıyor: geçmiş günün doz kaydı ayrı bir
      // sorgu ister ve M13'ün kapsamı dışında — geçmişte satır hiç
      // çizilmemek, yanlış "alınmadı" göstermekten iyi.
      doses: isToday ? doses : const [],
      checkedSlotIds: log?.checkedSlotIds ?? const {},
      workoutDone: log?.workoutDone ?? false,
      weightLabel: weight?.toStringAsFixed(1),
      mealKcalByKind: kcalByKind,
      workoutDetail: widget.day == null || widget.day!.exercises.isEmpty
          ? null
          : context.l10n.todayExerciseCount(widget.day!.exercises.length),
    );

    final nowKey =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
    final next = isToday ? nextFlowRow(rows, nowKey) : null;
    final (done, total) = flowProgress(rows);

    final visible = _expanded || widget.readOnly
        ? rows
        : rows.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionLabel(
          context.l10n.dayFlowTitle,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$done/$total',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              // Slot ekleme buraya taşındı (T19.0): omurga listesi
              // silinince "+"nın tek evi akış başlığı kaldı.
              if (!widget.readOnly)
                if (widget.day case final day?)
                IconButton(
                  icon: const Icon(LucideIcons.plus, size: 18),
                  tooltip: context.l10n.planSlotNew,
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      showSlotEditorSheet(context, dayId: day.id),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final row in visible)
          _FlowRow(
            row: row,
            highlighted: identical(row, next),
            date: date,
            day: widget.day,
            readOnly: widget.readOnly,
          ),
        // Düğme her zaman görünür: akış kısa olsa da ölçüm, kural ve
        // not bölümleri onun arkasında — satır sayısına bağlansaydı
        // plansız günde bu üçüne hiç ulaşılamazdı. Gelecek günde kayıt
        // alanları da düğme de yok — akış zaten tamamı.
        if (!widget.readOnly) ...[
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 18,
              ),
              label: Text(
                _expanded
                    ? context.l10n.dayFlowCollapse
                    : context.l10n.dayFlowExpand(rows.length),
              ),
            ),
          ),
        ],
        if (_expanded && !widget.readOnly) ...[
          const SizedBox(height: AppSpacing.xl),
          // Su Ana Sayfa'dan da girilebilmeli (v3 §5.1) — Diyet'e
          // geçmeden bardak eklemek günün en sık kaydı.
          const WaterRow(),
          const SizedBox(height: AppSpacing.xl),
          const MeasurementInputs(),
          const SizedBox(height: AppSpacing.xl),
          const DailyFlagsCard(),
          const SizedBox(height: AppSpacing.xl),
          const DayNoteField(),
        ],
      ],
    );
  }
}

class _FlowRow extends ConsumerWidget {
  const _FlowRow({
    required this.row,
    required this.highlighted,
    required this.date,
    required this.day,
    this.readOnly = false,
  });

  final DayFlowRow row;
  final bool highlighted;
  final String date;
  final FullPlanDay? day;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final semantic = context.semantic;

    final (IconData icon, AppArea area) = switch (row.kind) {
      DayFlowKind.weighIn => (LucideIcons.scale, AppArea.health),
      DayFlowKind.meal => (LucideIcons.utensils, AppArea.diet),
      DayFlowKind.workout => (LucideIcons.dumbbell, AppArea.sport),
      DayFlowKind.dose => (LucideIcons.pill, AppArea.med),
      DayFlowKind.slotOther => (LucideIcons.circleDashed, AppArea.neutral),
    };

    final label = row.kind == DayFlowKind.weighIn
        ? context.l10n.dayFlowWeighIn
        : row.label;

    return AppAccentRow(
      color: semantic.areaSport,
      active: highlighted,
      child: InkWell(
        onTap: readOnly ? null : () => _handleTap(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  row.time,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              AppIconTile(icon: icon, area: area, small: true),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: row.done
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (row.detail case final detail?)
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (row.done)
                Icon(LucideIcons.check, size: 18, color: semantic.success)
              else if (row.kind == DayFlowKind.meal &&
                  row.mealKind != null &&
                  !readOnly)
                // Mockup B1: girilmemiş öğün "+ GİR" rozeti taşır —
                // dokunuş işaret değil kayıt açar.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: semantic.areaDietSurface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    context.l10n.dayFlowEnterMeal,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: semantic.areaDiet,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Satır dokunuşu satırın işlemini açar — v3'ün "akıştan işle" sözü.
  void _handleTap(BuildContext context, WidgetRef ref) {
    switch (row.kind) {
      case DayFlowKind.weighIn:
        // Ölçüm alanları alt sayfada: tartı akıştan girilir, ekranın
        // dibine kaydırmak gerekmez.
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (context) => Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
            ),
            child: const SingleChildScrollView(child: MeasurementInputs()),
          ),
        );
      case DayFlowKind.dose:
        // Dokunuş işareti kurar/kaldırır — kartla aynı davranış.
        ref
            .read(supplementsRepositoryProvider)
            .markTaken(
              supplementId: row.slotId!,
              isoDate: date,
              time: row.doseTime!,
              takenAt: row.done ? null : DateTime.now(),
            );
      case DayFlowKind.workout:
        // v3 §6.2: akıştaki antrenman satırı Planlanan/Yapılan'ı açar;
        // canlı sayaç oradan bir dokunuş uzakta ve geçmiş gün de aynı
        // yoldan düzeltilir.
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PlannedVsDoneScreen(dateKey: date),
          ),
        );
      case DayFlowKind.meal:
        // Mockup: "öğün → seçici". Öğünlü satır besin seçiciyi açar;
        // yemek işaretlenmez, girilir. `mealKind`i olmayan eski slot
        // kutucuk davranışında kalır.
        if (row.mealKind case final kind?) {
          final repository = ref.read(nutritionRepositoryProvider);
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => FoodPickerScreen(
                mealKind: kind,
                onCopyLast: () =>
                    repository.copyMeal(mealKind: kind, toIsoDate: date),
                onPicked: (choice) => repository.addEntry(
                  food: choice.food,
                  mealKind: kind,
                  isoDate: date,
                  quantity: choice.quantity,
                  portion: choice.portion,
                  customGrams: choice.customGrams,
                ),
              ),
            ),
          );
        } else if (row.slotId case final slotId?) {
          ref.read(todayRepositoryProvider).toggleSlot(date, slotId);
        }
      case DayFlowKind.slotOther:
        if (row.slotId case final slotId?) {
          ref.read(todayRepositoryProvider).toggleSlot(date, slotId);
        }
    }
  }
}
