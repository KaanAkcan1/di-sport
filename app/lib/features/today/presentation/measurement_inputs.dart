import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_number.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/today/application/day_providers.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/presentation/sleep_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sabah tartısı ve uyku bloğu.
///
/// Ekranın en üstünde: PDF'in "her sabah tuvaletten sonra, aç karnına
/// tart" talimatı günün ilk işi ve uygulamanın en sık dokunulan yeri.
///
/// v3.1: uyku tek "saat" alanından [SleepBlock]'a çıktı — yatış/kalkış
/// gerçeği ve kestirme de giriliyor (spec v3.1 §2).
class MeasurementInputs extends ConsumerWidget {
  const MeasurementInputs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iso = ref.watch(viewedDateProvider);
    final repository = ref.watch(bodyMetricsRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricField(
          fieldKey: const Key('weight-field'),
          icon: Icons.monitor_weight_outlined,
          label: context.l10n.todayWeightLabel,
          unit: context.l10n.todayWeightUnit,
          value: ref.watch(dayWeightProvider(iso)),
          // Kaydedilen birim arayüz dilinden bağımsız: veri sabit
          // kalmalı, ekranda görünen etiket çevrilir.
          onSubmitted: (value) => repository.upsert(
            isoDate: iso,
            kind: MetricKinds.weight,
            value: value,
            unit: 'kg',
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SleepBlock(),
      ],
    );
  }
}

class _MetricField extends StatefulWidget {
  const _MetricField({
    required this.fieldKey,
    required this.icon,
    required this.label,
    required this.unit,
    required this.value,
    required this.onSubmitted,
  });

  /// Anahtar sarmalayıcıya değil `TextField`'a veriliyor: testler
  /// alanın kendisini bulup içeriğini okuyabilmeli.
  final Key fieldKey;

  final IconData icon;
  final String label;
  final String unit;
  final AsyncValue<double?> value;
  final void Function(double value) onSubmitted;

  @override
  State<_MetricField> createState() => _MetricFieldState();
}

class _MetricFieldState extends State<_MetricField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Odak kaybında da kaydet: kullanıcı klavyeyi kapatıp devam edince
    // yazdığı değerin kaybolması, veri girişinde en sinir bozucu hatadır.
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _submit(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final parsed = TurkishNumber.tryParse(raw);
    if (parsed != null && parsed > 0) widget.onSubmitted(parsed);
  }

  @override
  Widget build(BuildContext context) {
    // Kaydedilmiş değeri alana yansıt — kullanıcı yazarken değil, yalnız
    // odak dışındayken; aksi halde her tuşta imleç başa atlar.
    final stored = widget.value.value;
    if (!_focusNode.hasFocus) {
      final text = stored == null
          ? ''
          : TurkishNumber.format(stored);
      if (_controller.text != text) _controller.text = text;
    }

    return TextField(
      key: widget.fieldKey,
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        suffixText: widget.unit,
        prefixIcon: Icon(widget.icon),
      ),
      onSubmitted: _submit,
    );
  }
}
