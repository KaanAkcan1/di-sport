import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_date.dart';
import 'package:disport/core/utils/turkish_number.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/health/data/lab_repository.dart';
import 'package:disport/features/health/presentation/lab_range_bar.dart';
import 'package:flutter/material.dart';

/// Bir panelin marker satırları.
///
/// Panel başına kart, marker başına **tek** satır: ekranın işi geçmişi
/// dökmek değil bugünkü durumu göstermek. Değişim, son iki ölçümün
/// farkı olarak satırın içinde duruyor.
class LabPanelCard extends StatelessWidget {
  const LabPanelCard({super.key, required this.panel, required this.entries});

  final String panel;

  /// Panelin tüm kayıtları, **yeniden eskiye** sıralı (depo böyle verir).
  final List<LabEntry> entries;

  @override
  Widget build(BuildContext context) {
    final rows = _latestWithPrevious(entries);
    if (rows.isEmpty) return const SizedBox.shrink();

    // Panel özeti (v3 §7.1): kaç satır normal, kaçı dışarıda. Sayı
    // sıfırsa çip hiç çizilmez — "0 yüksek" gürültü.
    final statuses = [for (final row in rows) statusOf(row.latest)];
    final normal = statuses.where((s) => s == LabStatus.normal).length;
    final out = statuses
        .where((s) => s == LabStatus.low || s == LabStatus.high)
        .length;

    return AppSection(
      title: LabPanels.labelOf(panel),
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (normal > 0)
            AppStatusChip(
              status: AppStatus.good,
              label: '$normal',
              compact: true,
            ),
          if (out > 0) ...[
            const SizedBox(width: AppSpacing.xs),
            AppStatusChip(
              status: AppStatus.bad,
              label: '$out',
              compact: true,
            ),
          ],
        ],
      ),
      child: Card(
        child: Column(
          children: [
            for (final (index, row) in rows.indexed) ...[
              if (index > 0) const Divider(height: 1, indent: AppSpacing.lg),
              _LabRow(entry: row.latest, previous: row.previous),
            ],
          ],
        ),
      ),
    );
  }

  /// Marker başına son kayıt + bir öncekini eşler.
  ///
  /// Girdi yeniden eskiye sıralı olduğu için ilk görülen son kayıt,
  /// ikinci görülen bir öncekidir.
  static List<({LabEntry latest, LabEntry? previous})> _latestWithPrevious(
    List<LabEntry> entries,
  ) {
    final byMarker = <String, List<LabEntry>>{};
    for (final entry in entries) {
      (byMarker[entry.marker] ??= []).add(entry);
    }

    return [
      for (final list in byMarker.values)
        (latest: list.first, previous: list.length > 1 ? list[1] : null),
    ];
  }
}

class _LabRow extends StatelessWidget {
  const _LabRow({required this.entry, required this.previous});

  final LabEntry entry;
  final LabEntry? previous;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = statusOf(entry);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(entry.marker, style: theme.textTheme.titleSmall),
              ),
              const SizedBox(width: AppSpacing.md),
              AppMetricValue(
                value: entry.value,
                unit: entry.unit,
                color: _valueColor(context, status),
              ),
            ],
          ),
          // Aralık çubuğu (v3 §7.1): değer bandın neresinde. Renk +
          // konum + metin birlikte — üçü de aynı şeyi söylüyor.
          if (entry.refLow != null && entry.refHigh != null) ...[
            const SizedBox(height: AppSpacing.sm),
            LabRangeBar(
              value: entry.value,
              low: entry.refLow!,
              high: entry.refHigh!,
              inRange: status == LabStatus.normal,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  _subtitle(context),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppStatusChip(
                status: _appStatus(status),
                label: _statusLabel(context, status),
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Değerin kendisi yalnız referans **dışındaysa** renklenir.
  ///
  /// Normal değeri yeşile boyamak sayfayı yeşile boğar ve gerçekten
  /// bakılması gereken satırın dikkat çekmesini zorlaştırır — durum
  /// rozeti "normal" bilgisini zaten taşıyor.
  Color? _valueColor(BuildContext context, LabStatus status) =>
      switch (status) {
        LabStatus.low || LabStatus.high => _appStatus(status).color(context),
        _ => null,
      };

  String _subtitle(BuildContext context) {
    final parts = <String>[TurkishDate.isoToDayMonthYear(entry.date)];

    if (entry.refLow case final low?) {
      final high = entry.refHigh;
      if (high != null) {
        parts.add(
          context.l10n.healthLabRefRange(_trim(low), _trim(high)),
        );
      }
    }

    // Değişim yönü kasıtlı olarak renksiz: tahlilde "yukarı" iyi ya da
    // kötü demek değildir (TSH'nin yükselmesi ile D vitamininin
    // yükselmesi zıt anlamlar taşır). Yön bilgi, yorum kullanıcının.
    if (previous case final prev?) {
      final delta = entry.value - prev.value;
      final arrow = delta > 0
          ? '↑'
          : delta < 0
          ? '↓'
          : '→';
      parts.add('$arrow ${TurkishNumber.formatDelta(delta)}');
    }

    return parts.join(' · ');
  }

  /// Tam sayı referansları ondalıksız yazar.
  ///
  /// Laboratuvar kâğıdında "30-100" yazıyorsa ekranda "30,0-100,0"
  /// görmek kullanıcıya kendi kâğıdını tanımaz hâle getiriyor.
  static String _trim(double value) => value == value.roundToDouble()
      ? TurkishNumber.format(value, fractionDigits: 0)
      : TurkishNumber.format(value);

  static AppStatus _appStatus(LabStatus status) => switch (status) {
    LabStatus.normal => AppStatus.good,
    LabStatus.low || LabStatus.high => AppStatus.bad,
    LabStatus.unknown => AppStatus.unknown,
  };

  static String _statusLabel(BuildContext context, LabStatus status) =>
      switch (status) {
        LabStatus.low => context.l10n.healthLabStatusLow,
        LabStatus.high => context.l10n.healthLabStatusHigh,
        LabStatus.normal => context.l10n.healthLabStatusNormal,
        LabStatus.unknown => context.l10n.healthLabStatusNoRange,
      };
}
