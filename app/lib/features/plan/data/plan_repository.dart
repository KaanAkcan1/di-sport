import 'dart:convert';

import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/catalog/domain/exercise.dart' show Effort;
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/plan/domain/meal_kind.dart';
import 'package:drift/drift.dart';

/// Plan verisine erişimin tek kapısı.
class PlanRepository {
  PlanRepository(this._db);

  final AppDatabase _db;

  /// `yyyy-MM-dd`. Uygulama genelinde tarih anahtarı bu biçimde.
  static String iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Planı gün, slot ve hareketleriyle birlikte tek transaction'da yazar.
  ///
  /// Yarım yazma olmamalı: 28 günün 12'si yazılıp hata alınırsa kullanıcı
  /// bozuk bir planla kalır ve bunu fark etmesi günler sürer (spec 7.3,
  /// dördüncü kapı).
  Future<void> insertFullPlan(FullPlan plan) => _db.transaction(() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Aynı anda yalnız bir plan aktif olabilir.
    await (_db.update(_db.plans)..where((t) => t.isActive.equals(true))).write(
      const PlansCompanion(isActive: Value(false)),
    );

    await _db
        .into(_db.plans)
        .insertOnConflictUpdate(
          PlansCompanion.insert(
            id: plan.id,
            updatedAt: now,
            title: plan.title,
            startDate: iso(plan.startDate),
            endDate: iso(plan.endDate),
            weeks: plan.weeks,
            isActive: const Value(true),
            goalsJson: jsonEncode(plan.goals.toJson()),
            rulesJson: jsonEncode(plan.rules.toJson()),
            sourceRaw: Value(plan.sourceRaw),
          ),
        );

    for (final day in plan.days) {
      await _db
          .into(_db.planDays)
          .insertOnConflictUpdate(
            PlanDaysCompanion.insert(
              id: day.id,
              updatedAt: now,
              planId: plan.id,
              date: iso(day.date),
              type: day.type.name,
              weekIndex: day.weekIndex,
              headline: Value(day.headline),
              dinnerSuggestion: Value(day.dinnerSuggestion),
            ),
          );

      for (final (index, slot) in day.slots.indexed) {
        await _db
            .into(_db.planSlots)
            .insertOnConflictUpdate(
              PlanSlotsCompanion.insert(
                id: slot.id,
                updatedAt: now,
                planDayId: day.id,
                time: slot.time,
                kind: slot.kind.name,
                mealKind: Value(slot.mealKind?.name),
                label: slot.label,
                note: Value(slot.note),
                orderIndex: index,
              ),
            );

        // Kalemler slotla birlikte baştan yazılır: aynı plan yeniden
        // içeri alındığında eski kalemler hayalet olarak kalmasın.
        await (_db.delete(_db.planMealItems)
              ..where((t) => t.planSlotId.equals(slot.id)))
            .go();
        for (final (itemIndex, item) in slot.items.indexed) {
          await _db
              .into(_db.planMealItems)
              .insert(
                PlanMealItemsCompanion.insert(
                  id: '${slot.id}-i$itemIndex',
                  updatedAt: now,
                  planSlotId: slot.id,
                  foodId: item.foodId,
                  quantity: Value(item.quantity),
                  portionId: Value(item.portionId),
                ),
              );
        }
      }

      for (final (index, exercise) in day.exercises.indexed) {
        await _db
            .into(_db.planExercises)
            .insertOnConflictUpdate(
              PlanExercisesCompanion.insert(
                id: exercise.id,
                updatedAt: now,
                planDayId: day.id,
                exerciseId: exercise.exerciseId,
                orderIndex: index,
                sets: Value(exercise.sets),
                reps: Value(exercise.reps),
                durationSec: Value(exercise.durationSec),
                restSec: Value(exercise.restSec),
                intensity: Value(exercise.intensity),
                note: Value(exercise.note),
              ),
            );
      }
    }
  });

  Future<FullPlan?> activePlan() async {
    final row =
        await (_db.select(_db.plans)..where(
              (t) => t.isActive.equals(true) & t.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (row == null) return null;

    final dayRows =
        await (_db.select(_db.planDays)
              ..where((t) => t.planId.equals(row.id) & t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.date)]))
            .get();

    final days = <FullPlanDay>[];
    for (final dayRow in dayRows) {
      days.add(await _hydrateDay(dayRow));
    }

    return FullPlan(
      id: row.id,
      title: row.title,
      startDate: DateTime.parse(row.startDate),
      weeks: row.weeks,
      goals: PlanGoals.fromJson(
        jsonDecode(row.goalsJson) as Map<String, dynamic>,
      ),
      rules: PlanRules.fromJson(
        jsonDecode(row.rulesJson) as Map<String, dynamic>,
      ),
      days: days,
      sourceRaw: row.sourceRaw,
    );
  }

  /// Aktif planın verilen günü; veritabanı değiştikçe yenilenir.
  ///
  /// Bugün ekranı bunu dinler: kullanıcı yeni plan içeri aldığında ekran
  /// kendiliğinden güncellenir.
  Stream<FullPlanDay?> watchDay(String isoDate) {
    final query = _db.select(_db.planDays).join([
      innerJoin(_db.plans, _db.plans.id.equalsExp(_db.planDays.planId)),
    ])..where(
      _db.plans.isActive.equals(true) &
          _db.plans.deletedAt.isNull() &
          _db.planDays.deletedAt.isNull() &
          _db.planDays.date.equals(isoDate),
    );

    return query.watchSingleOrNull().asyncMap((row) async {
      if (row == null) return null;
      return _hydrateDay(row.readTable(_db.planDays));
    });
  }

  Future<bool> hasPlanFor(String isoDate) async {
    final row =
        await (_db.select(_db.planDays).join([
              innerJoin(_db.plans, _db.plans.id.equalsExp(_db.planDays.planId)),
            ])..where(
              _db.plans.isActive.equals(true) &
                  _db.plans.deletedAt.isNull() &
                  _db.planDays.date.equals(isoDate),
            ))
            .getSingleOrNull();
    return row != null;
  }

  /// Planı silinmiş işaretler. Günlük kayıtlar (`daily_logs`) plandan
  /// bağımsız yaşar; plan silinse de geçmiş kayıt kaybolmaz.
  Future<void> deletePlan(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.plans)..where((t) => t.id.equals(id))).write(
      PlansCompanion(
        deletedAt: Value(now),
        isActive: const Value(false),
        updatedAt: Value(now),
      ),
    );
  }

  Future<FullPlanDay> _hydrateDay(PlanDayRow row) async {
    final slotRows =
        await (_db.select(_db.planSlots)
              ..where((t) => t.planDayId.equals(row.id) & t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
            .get();

    // Kalemler slot başına değil gün başına tek sorguda: slot sayısı
    // kadar sorgu atmak gün ekranının her çiziminde gereksiz gidiş
    // geliş olurdu.
    final itemRows = slotRows.isEmpty
        ? const <PlanMealItemRow>[]
        : await (_db.select(_db.planMealItems)..where(
                (t) =>
                    t.planSlotId.isIn([for (final s in slotRows) s.id]) &
                    t.deletedAt.isNull(),
              ))
              .get();
    final itemsBySlot = <String, List<PlanMealItem>>{};
    for (final item in itemRows) {
      itemsBySlot
          .putIfAbsent(item.planSlotId, () => [])
          .add(
            PlanMealItem(
              foodId: item.foodId,
              quantity: item.quantity,
              portionId: item.portionId,
            ),
          );
    }

    final exerciseRows =
        await (_db.select(_db.planExercises)
              ..where((t) => t.planDayId.equals(row.id) & t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
            .get();

    return FullPlanDay(
      id: row.id,
      date: DateTime.parse(row.date),
      type: PlanDayType.values.byName(row.type),
      weekIndex: row.weekIndex,
      headline: row.headline,
      dinnerSuggestion: row.dinnerSuggestion,
      slots: [
        for (final slot in slotRows)
          PlanSlot(
            id: slot.id,
            time: slot.time,
            kind: SlotKind.values.byName(slot.kind),
            mealKind: switch (slot.mealKind) {
              final name? => MealKind.fromName(name),
              null => null,
            },
            items: itemsBySlot[slot.id] ?? const [],
            label: slot.label,
            note: slot.note,
          ),
      ],
      exercises: [
        for (final exercise in exerciseRows)
          PlanExercise(
            id: exercise.id,
            exerciseId: exercise.exerciseId,
            sets: exercise.sets,
            reps: exercise.reps,
            durationSec: exercise.durationSec,
            restSec: exercise.restSec,
            intensity: exercise.intensity,
            speedKmh: exercise.speedKmh,
            gradePct: exercise.gradePct,
            effort: switch (exercise.effort) {
              final name? => Effort.values.byName(name),
              null => null,
            },
            note: exercise.note,
          ),
      ],
    );
  }
}
