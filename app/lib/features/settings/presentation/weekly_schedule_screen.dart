import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_typography.dart';
import 'package:disport/core/utils/turkish_date.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/settings/application/settings_providers.dart';
import 'package:disport/features/settings/data/weekly_windows_repository.dart';
import 'package:disport/features/settings/domain/weekly_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Haftalık mesai ve uygun olunmayan saatler.
///
/// İkisi tek ekranda çünkü kullanıcı için tek bir soru: "haftan nasıl
/// geçiyor". Ayrı ekranlara bölmek aynı bilgiyi iki yerden girdirirdi.
class WeeklyScheduleScreen extends ConsumerWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windows = ref.watch(weeklyWindowsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Haftalık düzen')),
      body: AppAsyncView<List<WeeklyWindow>>(
        value: windows,
        onRetry: () => ref.invalidate(weeklyWindowsProvider),
        data: (list) => AppScreenBody(
          children: [
            const _Explanation(),
            const SizedBox(height: AppSpacing.xl),
            for (var weekday = 1; weekday <= 7; weekday++)
              _DayCard(
                weekday: weekday,
                windows: [
                  for (final w in list)
                    if (w.weekday == weekday) w,
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-window-fab'),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _WindowSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Saat aralığı'),
      ),
    );
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İki tür aralık var',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Fark açıkça yazılıyor: ikisi de "meşgulüm" gibi
            // görünüyor ama sonuçları farklı.
            Text(
              '· Mesai: iştesin. Yapay zekâ bu saatlere antrenman '
              'koymaz ama öğün koyabilir.\n'
              '· Uygun değil: hiçbir şey planlanmaz ve bu saatlerde '
              'bildirim çalmaz.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCard extends ConsumerWidget {
  const _DayCard({required this.weekday, required this.windows});

  final int weekday;
  final List<WeeklyWindow> windows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  TurkishDate.weekdaysShort[weekday - 1],
                  style: AppTypography.statCaption.copyWith(
                    color: windows.isEmpty
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Expanded(
                child: windows.isEmpty
                    ? Text(
                        'boş',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final window in windows)
                            _WindowChip(window: window),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WindowChip extends ConsumerWidget {
  const _WindowChip({required this.window});

  final WeeklyWindow window;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final blocked = window.kind == WindowKinds.blocked;

    return InputChip(
      key: Key('window-${window.id}'),
      avatar: Icon(
        blocked ? Icons.block : Icons.work_outline,
        size: 16,
        // Yasaklı aralık uyarı tonunda: "burada bir şey olamaz"
        // bilgisi mesaiden daha kısıtlayıcı.
        color: blocked
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(
        window.label.isEmpty
            ? '${window.startTime}–${window.endTime}'
            : '${window.startTime}–${window.endTime} · ${window.label}',
      ),
      onDeleted: () =>
          ref.read(weeklyWindowsRepositoryProvider).remove(window.id),
      deleteIcon: const Icon(Icons.close, size: 16),
    );
  }
}

/// Aralık ekleme formu.
class _WindowSheet extends ConsumerStatefulWidget {
  const _WindowSheet();

  @override
  ConsumerState<_WindowSheet> createState() => _WindowSheetState();
}

class _WindowSheetState extends ConsumerState<_WindowSheet> {
  final _label = TextEditingController();

  /// Varsayılan hafta içi: mesai en sık girilen şey ve genelde
  /// Pazartesi-Cuma.
  final _days = <int>{1, 2, 3, 4, 5};

  var _kind = WindowKinds.work;
  var _start = const TimeOfDay(hour: 8, minute: 0);
  var _end = const TimeOfDay(hour: 17, minute: 0);
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  String _format(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pick({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null) return;
    setState(() => isStart ? _start = picked : _end = picked);
  }

  Future<void> _save() async {
    if (_days.isEmpty) {
      setState(() => _error = 'En az bir gün seç');
      return;
    }

    await ref
        .read(weeklyWindowsRepositoryProvider)
        .addForDays(
          weekdays: _days.toList()..sort(),
          startTime: _format(_start),
          endTime: _format(_end),
          kind: _kind,
          label: _label.text,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.screenH),
          children: [
            Text('Saat aralığı ekle', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),

            SegmentedButton<String>(
              key: const Key('window-kind'),
              segments: const [
                ButtonSegment(
                  value: WindowKinds.work,
                  icon: Icon(Icons.work_outline),
                  label: Text('Mesai'),
                ),
                ButtonSegment(
                  value: WindowKinds.blocked,
                  icon: Icon(Icons.block),
                  label: Text('Uygun değil'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (values) =>
                  setState(() => _kind = values.first),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('Günler', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (var weekday = 1; weekday <= 7; weekday++)
                  FilterChip(
                    key: Key('day-$weekday'),
                    label: Text(TurkishDate.weekdaysShort[weekday - 1]),
                    selected: _days.contains(weekday),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _days.add(weekday);
                      } else {
                        _days.remove(weekday);
                      }
                      _error = null;
                    }),
                  ),
              ],
            ),
            if (_error case final message?) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),

            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    fieldKey: const Key('window-start'),
                    label: 'Başlangıç',
                    value: _format(_start),
                    onTap: () => _pick(isStart: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _TimeField(
                    fieldKey: const Key('window-end'),
                    label: 'Bitiş',
                    value: _format(_end),
                    onTap: () => _pick(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              // Gece yarısını aşan aralık destekleniyor; kullanıcı
              // uyku saatini ikiye bölmek zorunda kalmasın.
              'Bitiş başlangıçtan küçükse aralık gece yarısını aşar.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            TextField(
              key: const Key('window-label'),
              controller: _label,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                hintText: 'Fabrika',
                helperText: 'İsteğe bağlı',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            FilledButton(
              key: const Key('save-window'),
              onPressed: _save,
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final Key fieldKey;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      key: fieldKey,
      onTap: onTap,
      borderRadius: AppRadius.mdAll,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          value,
          style: AppTypography.timeRail.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
