import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:flutter/material.dart';

/// Slot türünün ikonu.
///
/// **Nerede yaşıyor ve neden:** `SlotKind` plan feature'ının
/// `domain`'inde; `core` hiçbir feature'ı import edemeyeceği için bu
/// eşleme `core/widgets`'a taşınamaz. Bugün ekranı buradan import
/// ediyor — feature'lar arası `presentation` bağımlılığı, bilinçli
/// ve tek yönlü (today → plan).
///
/// Renk taşımıyor: türü ikon anlatıyor, durumu (yapıldı/sırada/gelecek)
/// satırın kendisi renklendiriyor. İkonun da renk taşıması iki sinyali
/// üst üste bindirirdi.
IconData slotKindIcon(SlotKind kind) => switch (kind) {
  SlotKind.meal => Icons.restaurant_outlined,
  SlotKind.workout => Icons.fitness_center_outlined,
  SlotKind.sleep => Icons.bedtime_outlined,
  SlotKind.measurement => Icons.monitor_weight_outlined,
  SlotKind.lab => Icons.science_outlined,
  SlotKind.other => Icons.radio_button_unchecked,
};

/// Uyanma/kalkış — `SlotKind.measurement`'ın sabah özel hâli.
///
/// Ayrı sabit çünkü enum'a yeni değer eklemek plan verisini ve AI
/// sözleşmesini değiştirirdi; oysa bu yalnız bir görsel ayrım.
const wakeUpIcon = Icons.wb_sunny_outlined;

/// Slot türünün kullanıcıya görünen adı.
///
/// İkonun yanında duruyor: renk gibi ikon da tek başına anlam
/// taşımamalı ve editörde kullanıcının hangi türü seçtiğini okuması
/// gerekiyor.
String slotKindLabel(BuildContext context, SlotKind kind) {
  final l10n = context.l10n;
  return switch (kind) {
    SlotKind.meal => l10n.slotKindMeal,
    SlotKind.workout => l10n.slotKindWorkout,
    SlotKind.sleep => l10n.slotKindSleep,
    SlotKind.measurement => l10n.slotKindMeasurement,
    SlotKind.lab => l10n.slotKindLab,
    SlotKind.other => l10n.slotKindOther,
  };
}
