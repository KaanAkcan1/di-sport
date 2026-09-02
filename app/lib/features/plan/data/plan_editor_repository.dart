import 'dart:convert';

import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/catalog/domain/exercise.dart' show Effort;
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/plan/domain/meal_kind.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Planı **yazma** yolu.
///
/// **Neden `PlanRepository`'den ayrı:** okuma yolu her ekranda, yazma
/// yolu yalnız editörde. Aynı sınıfa koymak, plan gösteren her ekrana
/// yanlışlıkla plan silme yeteneği vermek olurdu.
///
/// **`sourceRaw` korunuyor:** planın kökeni olmaya devam ediyor,
/// tanımı olmaktan çıkıyor. Kullanıcı AI planını düzenlediğinde
/// orijinal belge yerinde kalır ve "AI bunu neden böyle demişti"
/// sorusu hâlâ cevaplanabilir.
class PlanEditorRepository {
  PlanEditorRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  // --- Plan düzeyi ---

  Future<void> updateTitle(String planId, String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      // l10n-exempt: geliştiriciye giden hata metni.
      throw ArgumentError.value(title, 'title', 'plan başlığı boş olamaz');
    }
    return _writePlan(planId, PlansCompanion(title: Value(trimmed)));
  }

  Future<void> updateGoals(String planId, PlanGoals goals) => _writePlan(
    planId,
    PlansCompanion(goalsJson: Value(jsonEncode(goals.toJson()))),
  );

  Future<void> updateRules(String planId, PlanRules rules) => _writePlan(
    planId,
    PlansCompanion(rulesJson: Value(jsonEncode(rules.toJson()))),
  );

  // --- Gün düzeyi ---

  Future<void> updateDay(
    String dayId, {
    PlanDayType? type,
    String? headline,
    String? dinnerSuggestion,
  }) =>
      (_db.update(_db.planDays)..where((t) => t.id.equals(dayId))).write(
        PlanDaysCompanion(
          type: type == null ? const Value.absent() : Value(type.name),
          headline: headline == null
              ? const Value.absent()
              : Value(headline.trim()),
          dinnerSuggestion: dinnerSuggestion == null
              ? const Value.absent()
              : Value(dinnerSuggestion.trim()),
          updatedAt: Value(_now),
        ),
      );

  // --- Slot düzeyi ---

  /// Yeni slot ekler ya da mevcut olanı günceller.
  ///
  /// Tek metot: editör sayfası "yeni mi düzenleme mi" ayrımını
  /// `slotId`'nin varlığından anlıyor ve çağıran iki ayrı yol yazmıyor.
  Future<String> upsertSlot(
    String dayId, {
    String? slotId,
    required String time,
    required SlotKind kind,
    required String label,
    MealKind? mealKind,
    List<PlanMealItem>? items,
    String? note,
  }) async {
    if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(time)) {
      // l10n-exempt: geliştiriciye giden hata metni.
      throw ArgumentError.value(time, 'time', 'saat HH:mm olmalı');
    }

    if (slotId != null) {
      // Kalemler null ise dokunulmaz (çağıran taşımadı); boş liste ise
      // bilinçli temizleme.
      if (items != null) {
        await _writeItems(
          slotId,
          kind == SlotKind.meal ? items : const <PlanMealItem>[],
        );
      }
      await (_db.update(_db.planSlots)..where((t) => t.id.equals(slotId)))
          .write(
            PlanSlotsCompanion(
              time: Value(time),
              kind: Value(kind.name),
              // Tür öğünden başka bir şeye çevrildiyse öğün türü
              // temizleniyor; kalırsa sonraki okuma "kahvaltı olan bir
              // antrenman" görürdü.
              mealKind: Value(
                kind == SlotKind.meal ? mealKind?.name : null,
              ),
              label: Value(label.trim()),
              note: Value(note?.trim()),
              updatedAt: Value(_now),
            ),
          );
      return slotId;
    }

    final id = _uuid.v4();
    await _db
        .into(_db.planSlots)
        .insert(
          PlanSlotsCompanion.insert(
            id: id,
            planDayId: dayId,
            time: time,
            kind: kind.name,
            label: label.trim(),
            mealKind: Value(kind == SlotKind.meal ? mealKind?.name : null),
            note: Value(note?.trim()),
            orderIndex: await _nextSlotOrder(dayId),
            updatedAt: _now,
          ),
        );
    if (items != null && kind == SlotKind.meal) {
      await _writeItems(id, items);
    }
    return id;
  }

  /// Slotun öğün kalemlerini baştan yazar (v3 §5.0).
  Future<void> _writeItems(String slotId, List<PlanMealItem> items) async {
    await (_db.delete(_db.planMealItems)
          ..where((t) => t.planSlotId.equals(slotId)))
        .go();
    for (final (index, item) in items.indexed) {
      await _db
          .into(_db.planMealItems)
          .insert(
            PlanMealItemsCompanion.insert(
              id: '$slotId-i$index',
              planSlotId: slotId,
              foodId: item.foodId,
              quantity: Value(item.quantity),
              portionId: Value(item.portionId),
              updatedAt: _now,
            ),
          );
    }
  }

  /// Yumuşak silme.
  ///
  /// **Bağlı öğün kayıtları bozulmuyor:** `meal_entries.slotId` zaten
  /// nullable ve o kayıtlar plansız kayda dönüyor. Kullanıcı bir slotu
  /// silince o gün yediklerinin de silinmesi felaket olurdu.
  Future<void> deleteSlot(String slotId) =>
      (_db.update(_db.planSlots)..where((t) => t.id.equals(slotId))).write(
        PlanSlotsCompanion(deletedAt: Value(_now), updatedAt: Value(_now)),
      );

  // --- Hareket düzeyi ---

  Future<String> upsertExercise(
    String dayId, {
    String? planExerciseId,
    required String exerciseId,
    int? sets,
    int? reps,
    int? durationSec,
    int? restSec,
    double? speedKmh,
    double? gradePct,
    Effort? effort,
    String? intensity,
    String? note,
  }) async {
    if (planExerciseId != null) {
      await (_db.update(
        _db.planExercises,
      )..where((t) => t.id.equals(planExerciseId))).write(
        PlanExercisesCompanion(
          exerciseId: Value(exerciseId),
          sets: Value(sets),
          reps: Value(reps),
          durationSec: Value(durationSec),
          restSec: Value(restSec),
          speedKmh: Value(speedKmh),
          gradePct: Value(gradePct),
          effort: Value(effort?.name),
          intensity: Value(intensity?.trim()),
          note: Value(note?.trim()),
          updatedAt: Value(_now),
        ),
      );
      return planExerciseId;
    }

    final id = _uuid.v4();
    await _db
        .into(_db.planExercises)
        .insert(
          PlanExercisesCompanion.insert(
            id: id,
            planDayId: dayId,
            exerciseId: exerciseId,
            orderIndex: await _nextExerciseOrder(dayId),
            sets: Value(sets),
            reps: Value(reps),
            durationSec: Value(durationSec),
            restSec: Value(restSec),
            speedKmh: Value(speedKmh),
            gradePct: Value(gradePct),
            effort: Value(effort?.name),
            intensity: Value(intensity?.trim()),
            note: Value(note?.trim()),
            updatedAt: _now,
          ),
        );
    return id;
  }

  Future<void> deleteExercise(String planExerciseId) =>
      (_db.update(
        _db.planExercises,
      )..where((t) => t.id.equals(planExerciseId))).write(
        PlanExercisesCompanion(
          deletedAt: Value(_now),
          updatedAt: Value(_now),
        ),
      );

  // --- Boş plan ---

  /// Elle kurulan plan: gün iskeleti var, içerik yok.
  ///
  /// Günler `rest` tipiyle ve slotsuz açılıyor — kullanıcı ne yapacağını
  /// kendisi yazacak. Varsayılan slotlar koymak, silinecek satırlar
  /// üretmek olurdu.
  ///
  /// Aktif plan varsa **yenisi aktif olur, eskisi pasifleşir** — içe
  /// alma davranışının aynısı, iki yol arasında sürpriz olmasın.
  Future<String> createEmptyPlan({
    required String title,
    required DateTime startDate,
    required int weeks,
    required PlanGoals goals,
    PlanRules rules = const PlanRules(forbidden: [], free: []),
  }) async {
    if (weeks < 1) {
      // l10n-exempt: geliştiriciye giden hata metni.
      throw ArgumentError.value(weeks, 'weeks', 'plan en az bir hafta olmalı');
    }

    final planId = _uuid.v4();
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = start.add(Duration(days: weeks * 7 - 1));

    await _db.transaction(() async {
      await (_db.update(_db.plans)..where((t) => t.isActive.equals(true)))
          .write(
            PlansCompanion(isActive: const Value(false), updatedAt: Value(_now)),
          );

      await _db
          .into(_db.plans)
          .insert(
            PlansCompanion.insert(
              id: planId,
              title: title.trim(),
              startDate: PlanRepository.iso(start),
              endDate: PlanRepository.iso(end),
              weeks: weeks,
              isActive: const Value(true),
              goalsJson: jsonEncode(goals.toJson()),
              rulesJson: jsonEncode(rules.toJson()),
              // Boş: bu plan bir AI belgesinden doğmadı.
              sourceRaw: const Value(''),
              updatedAt: _now,
            ),
          );

      await _db.batch((batch) {
        batch.insertAll(_db.planDays, [
          for (var index = 0; index < weeks * 7; index++)
            PlanDaysCompanion.insert(
              id: _uuid.v4(),
              planId: planId,
              date: PlanRepository.iso(start.add(Duration(days: index))),
              type: PlanDayType.rest.name,
              weekIndex: index ~/ 7 + 1,
              updatedAt: _now,
            ),
        ]);
      });
    });

    return planId;
  }

  // --- Yardımcılar ---

  int get _now => DateTime.now().millisecondsSinceEpoch;

  Future<void> _writePlan(String planId, PlansCompanion values) =>
      (_db.update(_db.plans)..where((t) => t.id.equals(planId))).write(
        values.copyWith(updatedAt: Value(_now)),
      );

  /// Yeni satır listenin sonuna giriyor.
  ///
  /// Sıra numarası sayıdan değil **en büyükten** türetiliyor: silinmiş
  /// satırlar sayıyı düşürür ve iki satır aynı sıraya oturabilirdi.
  Future<int> _nextSlotOrder(String dayId) async {
    final rows = await (_db.select(
      _db.planSlots,
    )..where((t) => t.planDayId.equals(dayId))).get();
    return rows.fold<int>(
      0,
      (max, row) => row.orderIndex >= max ? row.orderIndex + 1 : max,
    );
  }

  Future<int> _nextExerciseOrder(String dayId) async {
    final rows = await (_db.select(
      _db.planExercises,
    )..where((t) => t.planDayId.equals(dayId))).get();
    return rows.fold<int>(
      0,
      (max, row) => row.orderIndex >= max ? row.orderIndex + 1 : max,
    );
  }
}
