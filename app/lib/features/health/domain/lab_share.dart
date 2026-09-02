import 'package:disport/features/health/data/lab_repository.dart';

/// Tahlil özetini doktora götürülecek düz metne çevirir (v3 §7.1) — saf.
///
/// Marker başına yalnız **son** değer: doktorun sorusu "şu an ne
/// durumda", tüm geçmiş değil. Değer + birim + hedef aralık + tarih;
/// biçim sade — mesaj uygulamasında da e-postada da okunur kalmalı.
String buildLabShareText(
  Map<String, List<LabEntry>> byPanel, {
  required String title,
}) {
  final buffer = StringBuffer('$title\n');

  for (final panel in LabPanels.ordered) {
    final entries = byPanel[panel];
    if (entries == null || entries.isEmpty) continue;

    buffer.writeln('\n${LabPanels.labelOf(panel)}');

    final seen = <String>{};
    for (final entry in entries) {
      // Liste yeniden eskiye sıralı; marker başına ilk görülen sondur.
      if (!seen.add(entry.marker)) continue;
      final range = entry.refLow != null && entry.refHigh != null
          ? ' (${_trim(entry.refLow!)}–${_trim(entry.refHigh!)})'
          : '';
      buffer.writeln(
        '- ${entry.marker}: ${_trim(entry.value)} ${entry.unit}$range · '
        '${entry.date}',
      );
    }
  }
  return buffer.toString();
}

String _trim(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();
