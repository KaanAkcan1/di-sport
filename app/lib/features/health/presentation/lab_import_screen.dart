import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/result/result.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_number.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/health/application/health_providers.dart';
import 'package:disport/features/health/data/lab_repository.dart';
import 'package:disport/features/health/domain/lab_import.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

/// Tahlil AI aktarımı akışı (v3 §9.5) — plan köprüsünün ikizi.
///
/// Üç adım: belgeyi kopyala → PDF ile AI'a ver → dönen JSON'u yapıştır.
/// Önizlemede şüpheli satırlar amber; dokununca düzeltilir. Onaysız
/// hiçbir şey yazılmaz.
class LabImportScreen extends ConsumerStatefulWidget {
  const LabImportScreen({super.key});

  @override
  ConsumerState<LabImportScreen> createState() => _LabImportScreenState();
}

class _LabImportScreenState extends ConsumerState<LabImportScreen> {
  final _paste = TextEditingController();
  String? _error;
  List<LabImportRow>? _rows;
  final _skipped = <int>{};

  @override
  void dispose() {
    _paste.dispose();
    super.dispose();
  }

  void _parse() {
    switch (parseLabImport(_paste.text)) {
      case Ok(value: final rows):
        setState(() {
          _rows = rows;
          _error = null;
          _skipped.clear();
          // Şüpheliler varsayılan atlanır: kullanıcı bakmadan
          // kaydolmasınlar. Dokunup düzeltince listeye girerler.
          for (final (index, row) in rows.indexed) {
            if (row.suspect) _skipped.add(index);
          }
        });
      case Err(failure: final failure):
        setState(() {
          _rows = null;
          _error = failure.message;
        });
    }
  }

  Future<void> _save() async {
    final rows = _rows;
    if (rows == null) return;
    final repository = ref.read(labRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmation = context.l10n.labImportSaved(
      rows.length - _skipped.length,
    );

    var saved = 0;
    for (final (index, row) in rows.indexed) {
      if (_skipped.contains(index)) continue;
      await repository.add(
        LabEntry(
          id: const Uuid().v4(),
          date: row.date,
          marker: row.marker,
          value: row.value,
          unit: row.unit,
          panel: row.panel,
          refLow: row.refLow,
          refHigh: row.refHigh,
        ),
      );
      saved++;
    }

    if (saved > 0) ref.invalidate(dueLabsProvider);
    messenger.showSnackBar(SnackBar(content: Text(confirmation)));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final rows = _rows;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.labImportTitle)),
      body: AppScreenBody(
        children: [
          _Step(index: 1, text: l10n.labImportStep1),
          Row(
            children: [
              OutlinedButton.icon(
                key: const Key('lab-import-copy'),
                icon: const Icon(Icons.copy, size: 16),
                label: Text(l10n.labImportCopyDoc),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final copied = l10n.labImportCopied;
                  await Clipboard.setData(
                    ClipboardData(text: buildLabImportDoc()),
                  );
                  messenger.showSnackBar(SnackBar(content: Text(copied)));
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton.icon(
                key: const Key('lab-import-share'),
                icon: const Icon(Icons.ios_share, size: 16),
                label: Text(l10n.labImportShareDoc),
                onPressed: () => SharePlus.instance.share(
                  ShareParams(text: buildLabImportDoc()),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _Step(index: 2, text: l10n.labImportStep2),
          const SizedBox(height: AppSpacing.lg),
          _Step(index: 3, text: l10n.labImportStep3),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const Key('lab-import-paste'),
            controller: _paste,
            maxLines: 5,
            style: theme.textTheme.bodySmall,
            decoration: InputDecoration(
              hintText: l10n.labImportPasteHint,
              errorText: _error,
              errorMaxLines: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            key: const Key('lab-import-parse'),
            onPressed: _parse,
            child: Text(l10n.labImportParse),
          ),

          if (rows != null) ...[
            const SizedBox(height: AppSpacing.xl),
            AppSectionLabel(l10n.labImportPreview),
            for (final (index, row) in rows.indexed)
              _PreviewRow(
                key: Key('lab-import-row-$index'),
                row: row,
                skipped: _skipped.contains(index),
                onToggle: () => setState(() {
                  if (!_skipped.remove(index)) _skipped.add(index);
                }),
                onEdit: () => _edit(index),
              ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              key: const Key('lab-import-save'),
              onPressed: rows.length == _skipped.length ? null : _save,
              child: Text(
                l10n.labImportSave(
                  rows.length - _skipped.length,
                  _skipped.length,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl4),
        ],
      ),
    );
  }

  Future<void> _edit(int index) async {
    final row = _rows![index];
    final value = TextEditingController(
      text: TurkishNumber.format(row.value),
    );
    final unit = TextEditingController(text: row.unit);
    final marker = TextEditingController(text: row.marker);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.labImportEditTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('lab-import-edit-marker'),
              controller: marker,
              decoration: InputDecoration(
                labelText: context.l10n.healthLabMarkerLabel,
              ),
            ),
            TextField(
              key: const Key('lab-import-edit-value'),
              controller: value,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: context.l10n.healthLabValueLabel,
              ),
            ),
            TextField(
              key: const Key('lab-import-edit-unit'),
              controller: unit,
              decoration: InputDecoration(
                labelText: context.l10n.healthLabUnitLabel,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('lab-import-edit-save'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );

    final parsed = TurkishNumber.tryParse(value.text);
    if (confirmed ?? false) {
      if (parsed == null || marker.text.trim().isEmpty) return;
      setState(() {
        _rows![index] = row.copyWith(
          value: parsed,
          unit: unit.text.trim(),
          marker: marker.text.trim(),
        );
        // Düzeltilen satır kayda girer.
        _skipped.remove(index);
      });
    }
    value.dispose();
    unit.dispose();
    marker.dispose();
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primaryContainer,
            ),
            child: Text(
              '$index',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    super.key,
    required this.row,
    required this.skipped,
    required this.onToggle,
    required this.onEdit,
  });

  final LabImportRow row;
  final bool skipped;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final l10n = context.l10n;

    final suspicionText = row.suspicions
        .map(
          (s) => switch (s) {
            LabSuspicion.unknownMarker => l10n.labImportUnknownMarker,
            LabSuspicion.unexpectedUnit => l10n.labImportUnexpectedUnit,
            LabSuspicion.implausibleValue => l10n.labImportImplausible,
          },
        )
        .join(' · ');

    return CheckboxListTile(
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      value: !skipped,
      onChanged: (_) => onToggle(),
      title: Row(
        children: [
          if (row.suspect)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Icon(
                Icons.warning_amber_outlined,
                size: 16,
                color: semantic.warning,
              ),
            ),
          Expanded(child: Text(row.marker)),
          Text(
            '${TurkishNumber.format(row.value)} ${row.unit}',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
      subtitle: row.suspect
          ? Text(
              suspicionText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: semantic.warning,
              ),
            )
          : Text(
              row.date,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      secondary: IconButton(
        icon: const Icon(Icons.edit_outlined, size: 18),
        tooltip: l10n.labImportEditTitle,
        onPressed: onEdit,
      ),
    );
  }
}
