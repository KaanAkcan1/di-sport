import 'package:disport/core/result/result.dart';
import 'package:disport/features/ai_bridge/domain/plan_json.dart';
import 'package:disport/features/ai_bridge/domain/plan_validator.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
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
    this.uuid = const Uuid(),
  });

  final Future<void> Function(FullPlan plan) insertPlan;
  final Future<void> Function(Exercise exercise) addExercise;
  final Uuid uuid;

  /// [acceptedNewExerciseIds] kullanıcının onayladığı yeni hareketler.
  ///
  /// Onaylanmayan bir hareket planda kullanılıyorsa import reddedilir:
  /// tanımı olmayan bir id'ye referans veren plan, Antrenman ekranında
  /// boş kart olarak görünürdü.
  Future<Result<ImportSummary>> import(
    ValidatedPlan validated, {
    required Set<String> acceptedNewExerciseIds,
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
