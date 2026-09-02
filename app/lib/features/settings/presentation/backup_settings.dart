import 'dart:io';

import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/settings/data/backup_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Yedek al / geri yükle.
class BackupSettings extends StatefulWidget {
  const BackupSettings({super.key, this.service = const BackupService()});

  final BackupService service;

  @override
  State<BackupSettings> createState() => _BackupSettingsState();
}

class _BackupSettingsState extends State<BackupSettings> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppSection(
      title: l10n.settingsBackupTitle,
      description: l10n.settingsBackupDescription,
      child: Card(
        child: Column(
          children: [
            ListTile(
              key: const Key('export-backup'),
              enabled: !_busy,
              leading: const Icon(Icons.ios_share),
              title: Text(l10n.settingsBackupExport),
              subtitle: Text(l10n.settingsBackupExportSubtitle),
              onTap: _busy ? null : _export,
            ),
            const Divider(height: 1, indent: AppSpacing.lg),
            ListTile(
              key: const Key('import-backup'),
              enabled: !_busy,
              leading: const Icon(Icons.settings_backup_restore),
              title: Text(l10n.settingsBackupImport),
              subtitle: Text(l10n.settingsBackupImportSubtitle),
              onTap: _busy ? null : _import,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export() async {
    // Paylaş metni await'ten önce okunuyor: sonrasında `context` artık
    // güvenli değil.
    final shareText = context.l10n.settingsBackupShareText;
    setState(() => _busy = true);
    try {
      // Önce uygulamanın geçici dizinine yazılıyor, sonra paylaşılıyor:
      // paylaş menüsü kullanıcının seçtiği yere kopyalıyor, uygulamanın
      // dış depolama izni gerekmiyor.
      final file = await widget.service.exportTo(await getTemporaryDirectory());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: shareText,
        ),
      );
    } on BackupException catch (error) {
      _tell(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final picked = await FilePicker.pickFile();
    final path = picked?.path;
    if (path == null || !mounted) return;

    if (!await _confirm()) return;

    setState(() => _busy = true);
    try {
      await widget.service.importFrom(File(path));
      if (!mounted) return;
      _tell(context.l10n.settingsBackupRestored);
    } on BackupException catch (error) {
      _tell(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Üstüne yazma geri alınabilir ama kullanıcı bunu bilmeli.
  Future<bool> _confirm() async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.settingsBackupConfirmTitle),
        content: Text(context.l10n.settingsBackupConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('confirm-import'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.settingsBackupConfirmAction),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  void _tell(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
