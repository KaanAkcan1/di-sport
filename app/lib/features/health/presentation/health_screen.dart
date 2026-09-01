import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_number.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart'
    show profileEntriesProvider;
import 'package:disport/features/ai_bridge/domain/context_md_builder.dart'
    show ProfileKeys;
import 'package:disport/features/health/application/health_providers.dart';
import 'package:disport/features/health/data/body_metric_table.dart'
    show MetricKinds;
import 'package:disport/features/health/data/lab_repository.dart';
import 'package:disport/features/health/data/metric_definitions_repository.dart';
import 'package:disport/features/health/domain/bmi.dart';
import 'package:disport/features/health/domain/lab_share.dart';
import 'package:disport/features/health/presentation/add_lab_sheet.dart';
import 'package:disport/features/health/presentation/body_measurements_card.dart';
import 'package:disport/features/health/presentation/checkup_guide_section.dart';
import 'package:disport/features/health/presentation/due_labs_banner.dart';
import 'package:disport/features/health/presentation/lab_panel_card.dart';
import 'package:disport/features/health/presentation/metrics_editor_screen.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

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
            _BmiRow(),
            const SizedBox(height: AppSpacing.md),
            _DueBanner(),
            _Measurements(),
            if (byPanel.isNotEmpty) _ShareRow(byPanel: byPanel),
            if (byPanel.isEmpty)
              AppEmptyState(
                icon: Icons.science_outlined,
                title: context.l10n.healthNoLabsTitle,
                description: context.l10n.healthNoLabsDescription,
              )
            else
              // Paneller sabit sırada: kullanıcı aradığı satırı hep aynı
              // yerde bulmalı, veri geldikçe kartlar yer değiştirmemeli.
              for (final panel in LabPanels.ordered)
                if (byPanel[panel] case final entries?)
                  LabPanelCard(panel: panel, entries: entries),
            CheckupGuideSection(byPanel: byPanel),
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
        label: Text(context.l10n.healthAddLabFab),
      ),
    );
  }
}

/// VKİ satırı (v3 §7.1) — kilo ve boydan canlı türetilir.
///
/// Onboarding'den taşınan değerlendirme: yeni kullanıcıya ilk ekranda
/// "obez" damgası kötü karşılamaydı, burada bağlamında.
class _BmiRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final weight =
        ref.watch(latestMetricsProvider).value?[MetricKinds.weight]?.value;
    final heightRaw =
        ref.watch(profileEntriesProvider).value?[ProfileKeys.heightCm];
    final height = double.tryParse(
      (heightRaw ?? '').replaceAll(',', '.'),
    );
    final bmi = bodyMassIndex(weightKg: weight, heightCm: height);
    if (bmi == null) return const SizedBox.shrink();

    final bmiClass = BmiClass.of(bmi);
    final (status, label) = switch (bmiClass) {
      BmiClass.underweight => (AppStatus.caution, l10n.bmiUnderweight),
      BmiClass.normal => (AppStatus.good, l10n.bmiNormal),
      BmiClass.overweight => (AppStatus.caution, l10n.bmiOverweight),
      BmiClass.obese => (AppStatus.bad, l10n.bmiObese),
    };

    return Row(
      children: [
        Expanded(
          child: Text(l10n.bmiRowTitle, style: theme.textTheme.titleSmall),
        ),
        Text(
          TurkishNumber.format(bmi, fractionDigits: 1),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(width: AppSpacing.sm),
        AppStatusChip(status: status, label: label, compact: true),
      ],
    );
  }
}

/// Tahlil özetini düz metin olarak dışa verir — doktora götürmek için.
class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.byPanel});

  final Map<String, List<LabEntry>> byPanel;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: const Key('share-labs'),
        icon: const Icon(Icons.ios_share, size: 18),
        label: Text(context.l10n.healthShareLabs),
        onPressed: () => SharePlus.instance.share(
          ShareParams(
            text: buildLabShareText(
              byPanel,
              title: context.l10n.healthShareTitle,
            ),
            subject: context.l10n.healthShareTitle,
          ),
        ),
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
    final definitions = ref.watch(periodicMetricsProvider).value ?? const [];

    // Akış olduğu için elle tazeleme gerekmiyor: yazılan değer
    // kendiliğinden geri geliyor.
    return BodyMeasurementsCard(
      definitions: definitions,
      latest: latest,
      onEdit: (definition) => _editMetric(
        context,
        ref,
        definition,
        latest[definition.kind]?.value,
      ),
      onManage: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const MetricsEditorScreen()),
      ),
    );
  }

  Future<void> _editMetric(
    BuildContext context,
    WidgetRef ref,
    MetricDefinition definition,
    double? current,
  ) async {
    final value = await showDialog<double>(
      context: context,
      builder: (_) => _MetricDialog(definition: definition, current: current),
    );
    if (value == null) return;

    await ref
        .read(bodyMetricsRepositoryProvider)
        .upsert(
          isoDate: ref.read(todayIsoProvider),
          kind: definition.kind,
          value: value,
          unit: definition.unit,
        );
  }
}

/// Tek ölçüm girişi.
///
/// Ayrı bir sayfa yerine diyalog: girilen tek bir sayı, sayfa açmak
/// bağlamı gereksiz yere koparırdı.
class _MetricDialog extends StatefulWidget {
  const _MetricDialog({required this.definition, required this.current});

  final MetricDefinition definition;
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
      title: Text(widget.definition.label),
      content: TextField(
        key: Key('metric-input-${widget.definition.kind}'),
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        decoration: InputDecoration(
          suffixText: widget.definition.unit,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.l10n.commonSave),
        ),
      ],
    );
  }
}
