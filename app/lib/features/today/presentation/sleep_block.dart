import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_number.dart';
import 'package:disport/features/today/application/day_providers.dart';
import 'package:disport/features/today/domain/sleep_duration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Uyku bloğu (v3.1 §2.3) — yatış/kalkış/kestirme + yalnız süre.
///
/// Profildeki saatler *şablon*, buradakiler *gerçek*: dün gece fiilen
/// kaçta yatıldı. Türetilen süre `body_metrics.sleepHours`'a da
/// yazılır (grafikler ve AI serisi kırılmasın); çift doğruluk
/// "son yazan kazanır" kuralıyla önlenir ve tüm yazımlar
/// [SleepWriter]'dan geçer.
///
/// Blok `sleepHours` ölçüm *tanımından* bağımsızdır: kullanıcı tanımı
/// ölçüm listesinden silmiş olsa da uyku gün kaydının parçası olarak
/// girilebilir.
class SleepBlock extends ConsumerWidget {
  const SleepBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final iso = ref.watch(viewedDateProvider);
    final log = ref.watch(dayLogProvider(iso)).value;
    final hours = ref.watch(daySleepProvider(iso)).value;

    final bed = log?.bedTime;
    final wake = log?.wakeTimeActual;
    final nap = log?.napMinutes;

    // Başlık satırındaki özet: saatler varsa onlardan, yoksa kayıtlı
    // süreden.
    final derived =
        sleepHoursFrom(bedTime: bed, wakeTime: wake, napMinutes: nap) ?? hours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.moon,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.sleepBlockTitle, style: theme.textTheme.titleSmall),
            const Spacer(),
            if (derived != null)
              Text(
                l10n.sleepTotal(
                  derived.floor(),
                  ((derived - derived.floor()) * 60).round(),
                ),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (bed != null || wake != null)
              IconButton(
                key: const Key('sleep-clear'),
                icon: const Icon(LucideIcons.x, size: 16),
                tooltip: l10n.sleepClear,
                visualDensity: VisualDensity.compact,
                onPressed: () => ref
                    .read(sleepWriterProvider)
                    .saveTimes(
                      iso,
                      bedTime: null,
                      wakeTime: null,
                      napMinutes: null,
                    ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _TimeChip(
                fieldKey: const Key('sleep-bed'),
                label: l10n.sleepBedLabel,
                value: bed,
                onPicked: (time) => ref
                    .read(sleepWriterProvider)
                    .saveTimes(
                      iso,
                      bedTime: time,
                      wakeTime: wake,
                      napMinutes: nap,
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _TimeChip(
                fieldKey: const Key('sleep-wake'),
                label: l10n.sleepWakeLabel,
                value: wake,
                onPicked: (time) => ref
                    .read(sleepWriterProvider)
                    .saveTimes(
                      iso,
                      bedTime: bed,
                      wakeTime: time,
                      napMinutes: nap,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _NumberField(
                fieldKey: const Key('sleep-nap'),
                label: l10n.sleepNapLabel,
                unit: l10n.sleepNapUnit,
                value: nap?.toString() ?? '',
                onSubmitted: (raw) {
                  final minutes = int.tryParse(raw.trim());
                  ref
                      .read(sleepWriterProvider)
                      .saveTimes(
                        iso,
                        bedTime: bed,
                        wakeTime: wake,
                        napMinutes: minutes,
                      );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _NumberField(
                fieldKey: const Key('sleep-hours-only'),
                label: l10n.sleepHoursOnlyLabel,
                unit: l10n.sleepHoursUnit,
                // Saatler girildiyse alan türetileni değil kendi son
                // girişini gösterir; karışıklığı önlemek için saat
                // varken boş bırakılıyor.
                value: (bed == null && wake == null && hours != null)
                    ? TurkishNumber.format(hours)
                    : '',
                onSubmitted: (raw) {
                  final parsed = TurkishNumber.tryParse(raw);
                  if (parsed != null && parsed > 0) {
                    ref.read(sleepWriterProvider).saveHoursOnly(iso, parsed);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onPicked,
  });

  final Key fieldKey;
  final String label;
  final String? value;
  final void Function(String hhmm) onPicked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      key: fieldKey,
      onPressed: () async {
        final now = TimeOfDay.now();
        final initial = _parse(value) ?? now;
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
          helpText: context.l10n.sleepPickTime,
        );
        if (picked == null) return;
        onPicked(
          '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}',
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value ?? '—', style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }

  static TimeOfDay? _parse(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}

/// Odak kaybında da kaydeden sayı alanı ([_MetricField] kalıbı).
class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.fieldKey,
    required this.label,
    required this.unit,
    required this.value,
    required this.onSubmitted,
  });

  final Key fieldKey;
  final String label;
  final String unit;
  final String value;
  final void Function(String raw) onSubmitted;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) widget.onSubmitted(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_focusNode.hasFocus && _controller.text != widget.value) {
      _controller.text = widget.value;
    }

    return TextField(
      key: widget.fieldKey,
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: widget.label,
        suffixText: widget.unit,
        isDense: true,
      ),
      onSubmitted: widget.onSubmitted,
    );
  }
}
