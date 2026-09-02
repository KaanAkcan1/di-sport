import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/plan/domain/meal_kind.dart';
import 'package:disport/features/supplements/domain/supplement.dart';

/// Akış satırının türü — dokunuş hangi işlemi açacak.
enum DayFlowKind { weighIn, meal, workout, dose, slotOther }

/// Günün akışındaki tek satır.
///
/// **Neden birleşik model:** v2'de Bugün ekranı beş ayrı bölümdü (öğün
/// kartı, takviye kartı, ölçüm, kurallar, not) ve kullanıcı gününü
/// görmek için beş listeyi alt alta kaydırıyordu. v3'te gün tek bir
/// zaman çizgisi: plan slotları, ilaç dozları ve tartı aynı sırada.
/// Model saf — ekranın "hangi satır sırada" sorusu emülatörsüz test
/// ediliyor.
class DayFlowRow {
  const DayFlowRow({
    required this.time,
    required this.kind,
    required this.label,
    required this.done,
    this.detail,
    this.slotId,
    this.doseTime,
    this.mealKind,
  });

  /// `HH:mm` — sıralama anahtarı.
  final String time;

  final DayFlowKind kind;
  final String label;

  /// Yapıldı/alındı/girildi mi.
  final bool done;

  /// İkincil satır — "486 kcal · 3 kalem", "108,9 kg".
  final String? detail;

  /// Plan slotu satırıysa kimliği (işaretleme/düzenleme için).
  final String? slotId;

  /// Doz satırıysa planlanan saati (işaretleme anahtarının parçası).
  final String? doseTime;

  /// Öğün satırıysa öğünün türü — dokunuş besin seçiciyi bununla açar.
  final MealKind? mealKind;
}

/// Günün akışını kurar.
///
/// [weighInTime] tartı satırının saati (kalkış + 15dk; boşsa 06:30).
/// [weightLabel] doluysa tartı yapılmış sayılır.
/// [checkedSlotIds] işaretli plan slotları; [workoutDone] antrenman
/// kutusu (slot işaretinden ayrı yaşıyor, v1'den beri).
///
/// [mealKcalByKind] öğün türü → o gün yenen kcal toplamı. Öğün
/// satırının "yapıldı"sı mockup B1 gereği **kayıttır**: öğüne kalem
/// girildiyse satır "Kahvaltı — 486 kcal" olur; kutucuk işareti öğün
/// için anlamsızlaştı (yemek yemek işaretlenmez, girilir). `mealKind`i
/// olmayan eski öğün slotları kutucuk davranışında kalır — onların
/// kaydı hangi öğüne yazılacak bilinemez.
List<DayFlowRow> buildDayFlow({
  required List<PlanSlot> slots,
  required List<SupplementDose> doses,
  required Set<String> checkedSlotIds,
  required bool workoutDone,
  String? weighInTime,
  String? weightLabel,
  Map<MealKind, double> mealKcalByKind = const {},
  String? workoutDetail,
}) {
  final rows = <DayFlowRow>[
    DayFlowRow(
      time: weighInTime ?? '06:30',
      kind: DayFlowKind.weighIn,
      label: '',
      done: weightLabel != null,
      detail: weightLabel,
    ),
    for (final slot in slots)
      DayFlowRow(
        time: slot.time,
        kind: switch (slot.kind) {
          SlotKind.meal => DayFlowKind.meal,
          SlotKind.workout => DayFlowKind.workout,
          _ => DayFlowKind.slotOther,
        },
        label: slot.label,
        done: switch ((slot.kind, slot.mealKind)) {
          (SlotKind.workout, _) => workoutDone,
          (SlotKind.meal, final kind?) =>
            (mealKcalByKind[kind] ?? 0) > 0,
          _ => checkedSlotIds.contains(slot.id),
        },
        slotId: slot.id,
        mealKind: slot.kind == SlotKind.meal ? slot.mealKind : null,
        detail: switch ((slot.kind, slot.mealKind)) {
          (SlotKind.meal, final kind?)
              when (mealKcalByKind[kind] ?? 0) > 0 =>
            '${mealKcalByKind[kind]!.round()} kcal',
          // Antrenman satırı hareket sayısını taşır (mockup SIRADA
          // kartıyla aynı dil) — slotun kendi notu varsa o kazanır.
          (SlotKind.workout, _) when (slot.note ?? '').isEmpty =>
            workoutDetail,
          _ => slot.note,
        },
      ),
    for (final dose in doses)
      DayFlowRow(
        time: dose.time,
        kind: DayFlowKind.dose,
        label: dose.supplement.name,
        done: dose.isTaken,
        doseTime: dose.time,
        slotId: dose.supplement.id,
        detail: [
          if (dose.supplement.dose.isNotEmpty) dose.supplement.dose,
          if (dose.supplement.unit.isNotEmpty) dose.supplement.unit,
        ].join(' '),
      ),
  ]..sort((a, b) => a.time.compareTo(b.time));

  return rows;
}

/// Akışta "sıradaki" satır: saati geçmemiş ilk yapılmamış iş.
///
/// Saati geçmiş ama yapılmamış satır "sırada" değildir — kaçmıştır;
/// onu vurgulamak kullanıcıyı geriye çağırır, oysa günün sorusu hep
/// "şimdi ne var".
DayFlowRow? nextFlowRow(List<DayFlowRow> rows, String nowHHmm) {
  for (final row in rows) {
    if (!row.done && row.time.compareTo(nowHHmm) >= 0) return row;
  }
  return null;
}

/// Akış özeti: yapılmış / toplam.
(int done, int total) flowProgress(List<DayFlowRow> rows) =>
    (rows.where((row) => row.done).length, rows.length);
