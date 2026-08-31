import 'package:disport/core/utils/turkish_number.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/health/application/health_providers.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/health/data/lab_repository.dart';
import 'package:disport/features/health/presentation/add_lab_sheet.dart';
import 'package:disport/features/health/presentation/body_measurements_card.dart';
import 'package:disport/features/health/presentation/due_labs_banner.dart';
import 'package:disport/features/health/presentation/lab_panel_card.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sağlık sekmesi: vadesi gelen tahliller, ölçümler, panel kartları.
///
/// Sıra bilinçli — eylem gerektiren en üstte (vade şeridi), sonra
/// kullanıcının kendi girdiği ölçümler, en altta geçmişi anlatan
/// tahlil panelleri.
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labs = ref.watch(labsByPanelProvider);

    return Scaffold(
      // Kabuğun `Scaffold`'unun içinde ikinci bir `Scaffold`: yalnız
      // bu sekmeye ait bir FAB gerekiyor. `IndexedStack` seçili olmayan
      // çocuğu boyamadığı için diğer sekmelerin FAB'ları görünmez.
      backgroundColor: Colors.transparent,
      body: AppAsyncView<Map<String, List<LabEntry>>>(
        value: labs,
        onRetry: () => ref.invalidate(labsByPanelProvider),
        data: (byPanel) => AppScreenBody(
          children: [
            _DueBanner(),
            _Measurements(),
            if (byPanel.isEmpty)
              const AppEmptyState(
                icon: Icons.science_outlined,
                title: 'Tahlil kaydı yok',
                description: 'Elindeki tahlil sonuçlarını ekle; referans '
                    'aralığını da girersen değerin düşük mü yüksek mi '
                    'olduğunu takip edebilirim.',
              )
            else
              // Paneller sabit sırada: kullanıcı aradığı satırı hep aynı
              // yerde bulmalı, veri geldikçe kartlar yer değiştirmemeli.
              for (final panel in LabPanels.ordered)
                if (byPanel[panel] case final entries?)
                  LabPanelCard(panel: panel, entries: entries),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-lab-fab'),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const AddLabSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tahlil'),
      ),
    );
  }
}

class _DueBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Vade bilgisi ekranın çalışması için şart değil; yüklenirken ya da
    // hata alırken sessizce boş kalır, tahlil listesi yine görünür.
    final due = ref.watch(dueLabsProvider).value ?? const [];
    return DueLabsBanner(due: due);
  }
}

class _Measurements extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestMetricsProvider).value ?? const {};

    return BodyMeasurementsCard(
      latest: latest,
      onEdit: (kind) => _editMetric(context, ref, kind, latest[kind]?.value),
    );
  }

  Future<void> _editMetric(
    BuildContext context,
    WidgetRef ref,
    String kind,
    double? current,
  ) async {
    final value = await showDialog<double>(
      context: context,
      builder: (_) => _MetricDialog(kind: kind, current: current),
    );
    if (value == null) return;

    await ref
        .read(bodyMetricsRepositoryProvider)
        .upsert(
          isoDate: ref.read(todayIsoProvider),
          kind: kind,
          value: value,
          unit: MetricKinds.unitOf(kind),
        );
    ref.invalidate(latestMetricsProvider);
  }
}

/// Tek ölçüm girişi.
///
/// Ayrı bir sayfa yerine diyalog: girilen tek bir sayı, sayfa açmak
/// bağlamı gereksiz yere koparırdı.
class _MetricDialog extends StatefulWidget {
  const _MetricDialog({required this.kind, required this.current});

  final String kind;
  final double? current;

  @override
  State<_MetricDialog> createState() => _MetricDialogState();
}

class _MetricDialogState extends State<_MetricDialog> {
  late final _controller = TextEditingController(
    text: widget.current == null
        ? ''
        : TurkishNumber.format(widget.current!),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = TurkishNumber.tryParse(_controller.text);
    Navigator.of(context).pop(parsed != null && parsed > 0 ? parsed : null);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(MetricKinds.labelOf(widget.kind)),
      content: TextField(
        key: Key('metric-input-${widget.kind}'),
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        decoration: InputDecoration(
          suffixText: MetricKinds.unitOf(widget.kind),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Kaydet')),
      ],
    );
  }
}
