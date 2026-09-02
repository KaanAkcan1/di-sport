import 'package:disport/core/result/result.dart';
import 'package:disport/features/ai_bridge/domain/plan_json.dart';
import 'package:disport/features/ai_bridge/domain/plan_validator.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/plan/domain/meal_kind.dart';
import 'package:uuid/uuid.dart';

/// İçe alma sonucu.
class ImportSummary {
  const ImportSummary({
    required this.planId,
    required this.dayCount,
    required this.addedExercises,
  });

  final String planId;
  final int dayCount;
  final int addedExercises;
}

/// Doğrulanmış planı domain'e çevirip kaydeder.
///
/// Depo tiplerini değil **fonksiyon imzalarını** alıyor: `ai_bridge`
/// feature'ların `data/` katmanını import edemez (spec 4.3). Yan fayda,
/// testte sahte kayıt fonksiyonlarıyla çalışabilmesi.
class PlanImporter {
  const PlanImporter({
    required this.insertPlan,
    required this.addExercise,
    this.loadActivePlan,
    this.pruneDays,
    this.uuid = const Uuid(),
  });

  final Future<void> Function(FullPlan plan) insertPlan;
  final Future<void> Function(Exercise exercise) addExercise;

  /// Aşılama için (v3 §9.1). Verilmezse aşılama yapılamaz — eski
  /// çağıranlar değişmeden çalışır.
  final Future<FullPlan?> Function()? loadActivePlan;

  /// Kesim tarihinden sonraki eski günleri düşürür.
  final Future<void> Function(String planId, Set<String> keepDayIds)?
  pruneDays;

  final Uuid uuid;

  /// [acceptedNewExerciseIds] kullanıcının onayladığı yeni hareketler.
  ///
  /// Onaylanmayan bir hareket planda kullanılıyorsa import reddedilir:
  /// tanımı olmayan bir id'ye referans veren plan, Antrenman ekranında
  /// boş kart olarak görünürdü.
  Future<Result<ImportSummary>> import(
    ValidatedPlan validated, {
    required Set<String> acceptedNewExerciseIds,
    bool graft = false,
  }) async {
    final plan = validated.plan;

    final rejected = {
      for (final candidate in plan.newExercises)
        if (!acceptedNewExerciseIds.contains(candidate.id)) candidate.id,
    };

    final usedButRejected = <String>{};
    for (final day in plan.days) {
      for (final exercise in day.exercises) {
        if (rejected.contains(exercise.exerciseId)) {
          usedButRejected.add(exercise.exerciseId);
        }
      }
    }

    if (usedButRejected.isNotEmpty) {
      return Err(
        Failure(
          message:
              'Plan şu yeni hareketleri kullanıyor ama onaylamadın: '
              '${usedButRejected.join(", ")}.\n'
              'Ya onayla ya da AI\'dan bu hareketleri kullanmayan bir '
              'sürüm iste.',
        ),
      );
    }

    var added = 0;
    for (final candidate in plan.newExercises) {
      if (!acceptedNewExerciseIds.contains(candidate.id)) continue;

      final data = Map<String, dynamic>.from(candidate.data)
        ..['isUserDefined'] = true;
      await addExercise(Exercise.fromJson(data));
      added++;
    }

    // Aşılama (v3 §9.1): dönen plan mevcut aktif planın üstüne,
    // başlangıç tarihinden itibaren aşılanır. Önceki günler ve tüm
    // tarihli kayıtlar aynen kalır.
    if (graft) {
      final active = await loadActivePlan?.call();
      if (active != null) {
        final merged = _graft(plan, active, validated.rawJson);
        await insertPlan(merged);
        await pruneDays?.call(
          active.id,
          {for (final day in merged.days) day.id},
        );
        return Ok(
          ImportSummary(
            planId: active.id,
            dayCount: plan.days.length,
            addedExercises: added,
          ),
        );
      }
    }

    final planId = uuid.v4();
    await insertPlan(_toDomain(plan, planId, validated.rawJson));

    return Ok(
      ImportSummary(
        planId: planId,
        dayCount: plan.days.length,
        addedExercises: added,
      ),
    );
  }

  /// Dönen planı aktif planın üstüne aşılar (v3 §9.1).
  ///
  /// - Kesim = dönen planın ilk günü. Öncesi aynen korunur.
  /// - `startDate` değişmez; `endDate` en geç günden, `weeks` ondan.
  /// - **Tüm** `weekIndex` değerleri `startDate`'e göre tarih
  ///   aritmetiğiyle yeniden atanır; dönen belgedeki hafta numaraları
  ///   yok sayılır.
  /// - `sourceRaw` planın kökeni: yeni belge sona eklenir, orijinal
  ///   yerinde kalır.
  FullPlan _graft(PlanJson incoming, FullPlan active, String rawJson) {
    final cut = DateTime.parse(incoming.meta.startDate);
    final base = DateTime(
      active.startDate.year,
      active.startDate.month,
      active.startDate.day,
    );

    int weekOf(DateTime date) =>
        DateTime(date.year, date.month, date.day).difference(base).inDays ~/
            7 +
        1;

    final kept = [
      for (final day in active.days)
        if (day.date.isBefore(cut))
          FullPlanDay(
            id: day.id,
            date: day.date,
            type: day.type,
            weekIndex: weekOf(day.date),
            headline: day.headline,
            dinnerSuggestion: day.dinnerSuggestion,
            slots: day.slots,
            exercises: day.exercises,
          ),
    ];

    // Yeni günlerin id'si tarihten türetiliyor: aynı belge iki kez
    // aşılanırsa satırlar çakışmadan üzerine yazılır.
    final incomingPlan = _toDomain(incoming, active.id, rawJson);
    final grafted = [
      for (final day in incomingPlan.days)
        FullPlanDay(
          id: '${active.id}-g${_iso(day.date)}',
          date: day.date,
          type: day.type,
          weekIndex: weekOf(day.date),
          headline: day.headline,
          dinnerSuggestion: day.dinnerSuggestion,
          slots: day.slots,
          exercises: day.exercises,
        ),
    ];

    final all = [...kept, ...grafted]
      ..sort((a, b) => a.date.compareTo(b.date));
    final lastDate = all.last.date;
    final weeks =
        (DateTime(
                  lastDate.year,
                  lastDate.month,
                  lastDate.day,
                ).difference(base).inDays +
            7) ~/
        7;

    return FullPlan(
      id: active.id,
      title: incoming.meta.title,
      startDate: active.startDate,
      weeks: weeks,
      goals: incomingPlan.goals,
      rules: incomingPlan.rules,
      sourceRaw: active.sourceRaw.isEmpty
          ? rawJson
          : '${active.sourceRaw}\n\n--- aşılama (${incoming.meta.startDate}) ---\n$rawJson',
      days: all,
    );
  }

  static String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  FullPlan _toDomain(PlanJson plan, String planId, String rawJson) {
    return FullPlan(
      id: planId,
      title: plan.meta.title,
      startDate: DateTime.parse(plan.meta.startDate),
      weeks: plan.meta.weeks,
      goals: PlanGoals(
        dailyKcal: plan.goals.dailyKcal,
        proteinG: plan.goals.proteinG,
        waterL: plan.goals.waterL,
        weeklyGym: plan.goals.weeklyGym,
        weeklyHome: plan.goals.weeklyHome,
        targetLossKg: plan.goals.targetLossKg,
      ),
      rules: PlanRules(
        forbidden: plan.rules.forbidden,
        free: plan.rules.free,
      ),
      sourceRaw: rawJson,
      days: [
        for (final (dayIndex, day) in plan.days.indexed)
          FullPlanDay(
            // Id'ler plan id'sinden türetiliyor: aynı plan iki kez içeri
            // alınırsa satırlar çakışmadan üzerine yazılıyor.
            id: '$planId-d$dayIndex',
            date: DateTime.parse(day.date),
            type: PlanDayType.values.byName(day.type),
            weekIndex: day.weekIndex,
            headline: day.headline,
            dinnerSuggestion: day.dinnerSuggestion,
            slots: [
              for (final (slotIndex, slot) in day.slots.indexed)
                PlanSlot(
                  id: '$planId-d$dayIndex-s$slotIndex',
                  time: slot.time,
                  kind: SlotKind.values.byName(slot.kind),
                  mealKind: slot.mealKind == null
                      ? null
                      : MealKind.fromName(slot.mealKind!),
                  items: [
                    for (final item in slot.items)
                      PlanMealItem(
                        foodId: item.foodId,
                        quantity: item.quantity,
                        portionId: item.portionId,
                      ),
                  ],
                  label: slot.label,
                  note: slot.note,
                ),
            ],
            exercises: [
              for (final (exerciseIndex, exercise) in day.exercises.indexed)
                PlanExercise(
                  id: '$planId-d$dayIndex-e$exerciseIndex',
                  exerciseId: exercise.exerciseId,
                  sets: exercise.sets,
                  reps: exercise.reps,
                  durationSec: exercise.durationSec,
                  restSec: exercise.restSec,
                  intensity: exercise.intensity,
                  note: exercise.note,
                ),
            ],
          ),
      ],
    );
  }
}
