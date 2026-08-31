import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/turkish_date.dart';
import 'package:disport/core/utils/turkish_number.dart';
import 'package:disport/features/health/application/health_providers.dart';
import 'package:disport/features/health/data/lab_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Tahlil ekleme formu.
///
/// Referans aralığı **zorunlu değil**: kullanıcı elindeki kâğıtta aralık
/// yazmıyorsa değeri hiç kaydedememesindense aralıksız kaydetmesi iyidir.
/// Aralıksız kayıt "aralık yok" olarak gösterilir, uydurma bir aralıkla
/// "normal" denmez.
class AddLabSheet extends ConsumerStatefulWidget {
  const AddLabSheet({super.key});

  @override
  ConsumerState<AddLabSheet> createState() => _AddLabSheetState();
}

class _AddLabSheetState extends ConsumerState<AddLabSheet> {
  final _formKey = GlobalKey<FormState>();
  final _marker = TextEditingController();
  final _value = TextEditingController();
  final _unit = TextEditingController();
  final _refLow = TextEditingController();
  final _refHigh = TextEditingController();
  final _labName = TextEditingController();

  var _panel = LabPanels.metabolic;
  var _date = DateTime.now();
  var _saving = false;

  @override
  void dispose() {
    for (final controller in [
      _marker,
      _value,
      _unit,
      _refLow,
      _refHigh,
      _labName,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    await ref
        .read(labRepositoryProvider)
        .add(
          LabEntry(
            id: const Uuid().v4(),
            date: _isoDate(_date),
            marker: _marker.text.trim(),
            value: TurkishNumber.tryParse(_value.text)!,
            unit: _unit.text.trim(),
            panel: _panel,
            refLow: TurkishNumber.tryParse(_refLow.text),
            refHigh: TurkishNumber.tryParse(_refHigh.text),
            labName: _labName.text.trim().isEmpty
                ? null
                : _labName.text.trim(),
          ),
        );

    if (!mounted) return;
    // Vade şeridi yeni kayıttan sonra değişebilir; akışa bağlı olmayan
    // future provider elle tazeleniyor.
    ref.invalidate(dueLabsProvider);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Klavye açıldığında alanların üstüne binmemesi için taban dolgusu
    // klavye yüksekliğini takip ediyor (ui-ux §5).
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(AppSpacing.screenH),
            children: [
              Text(
                'Tahlil ekle',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),

              TextFormField(
                key: const Key('lab-marker'),
                controller: _marker,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Tahlil adı',
                  hintText: 'Vitamin D',
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Tahlil adı gerekli'
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      key: const Key('lab-value'),
                      controller: _value,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [_decimalFormatter],
                      decoration: const InputDecoration(labelText: 'Değer'),
                      validator: (value) =>
                          TurkishNumber.tryParse(value ?? '') == null
                          ? 'Sayı girin'
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      key: const Key('lab-unit'),
                      controller: _unit,
                      decoration: const InputDecoration(
                        labelText: 'Birim',
                        hintText: 'ng/mL',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('lab-ref-low'),
                      controller: _refLow,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [_decimalFormatter],
                      decoration: const InputDecoration(
                        labelText: 'Referans alt',
                        helperText: 'İsteğe bağlı',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      key: const Key('lab-ref-high'),
                      controller: _refHigh,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [_decimalFormatter],
                      decoration: const InputDecoration(
                        labelText: 'Referans üst',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              DropdownButtonFormField<String>(
                key: const Key('lab-panel'),
                initialValue: _panel,
                decoration: const InputDecoration(labelText: 'Panel'),
                items: [
                  for (final panel in LabPanels.ordered)
                    DropdownMenuItem(
                      value: panel,
                      child: Text(LabPanels.labelOf(panel)),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _panel = value ?? _panel),
              ),
              const SizedBox(height: AppSpacing.lg),

              TextFormField(
                key: const Key('lab-name'),
                controller: _labName,
                decoration: const InputDecoration(
                  labelText: 'Laboratuvar',
                  helperText: 'İsteğe bağlı — aralıklar laboratuvara göre '
                      'değişir',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              ListTile(
                key: const Key('lab-date'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Tahlil tarihi'),
                subtitle: Text(TurkishDate.dayMonthYear(_date)),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _pickDate,
              ),
              const SizedBox(height: AppSpacing.xl),

              FilledButton(
                key: const Key('lab-save'),
                onPressed: _saving ? null : _save,
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      // Tahlil geçmişi yıllara yayılabilir; ileri tarih anlamsız.
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Rakam, virgül ve nokta dışına izin verilmiyor.
  static final _decimalFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'[0-9.,]'),
  );
}
