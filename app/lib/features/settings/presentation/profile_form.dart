import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/ai_bridge/domain/context_md_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Profil ve yaşam tarzı formu.
///
/// Hem ilk açılışta (onboarding) hem Ayarlar'da aynı form kullanılıyor:
/// alanların sırası ve etiketleri [ProfileKeys.form]'da tanımlı, iki
/// ekranın ayrışması mümkün değil.
///
/// Bu alanlar `context.md`'nin birinci ve üçüncü bölümünü besliyor;
/// eksik doldurulmuş bir profil AI'a "belirtilmedi" olarak gidiyor ve
/// plan jenerikleşiyor. O yüzden form neden sorulduğunu açıklıyor.
class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({
    super.key,
    this.onSaved,
    this.saveLabel = 'Kaydet',
    this.trailing = const [],
  });

  /// Onboarding'de kabuğa geçmek için; Ayarlar'da null.
  final VoidCallback? onSaved;

  final String saveLabel;

  /// Formdan sonra aynı kaydırma alanına eklenecek bölümler.
  ///
  /// Ayarlar ekranı bildirim ve yedekleme bölümlerini buradan geçiriyor.
  /// Ayrı bir `ListView` içine sarmak iç içe kaydırma yaratır: dış
  /// liste kaydırılırken iç liste takılır, kullanıcı ekranın "kilitli"
  /// olduğunu sanır.
  final List<Widget> trailing;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _controllers = <String, TextEditingController>{};
  var _initialised = false;
  var _saving = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String key) =>
      _controllers.putIfAbsent(key, TextEditingController.new);

  Future<void> _save() async {
    final height = _controllerFor(ProfileKeys.heightCm).text.trim();
    if (height.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Boy alanı gerekli.')),
      );
      return;
    }

    setState(() => _saving = true);

    final values = <String, String>{
      for (final entry in _controllers.entries)
        if (entry.value.text.trim().isNotEmpty)
          entry.key: entry.value.text.trim(),
    };

    await ref.read(profileRepositoryProvider).setAll(values);
    ref.invalidate(profileEntriesProvider);

    if (!mounted) return;
    setState(() => _saving = false);
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stored = ref.watch(profileEntriesProvider).value;

    // Kaydedilmiş değerleri bir kez alanlara yaz; sürekli senkronlarsak
    // kullanıcı yazarken imleç başa atlar.
    if (!_initialised && stored != null) {
      for (final entry in stored.entries) {
        _controllerFor(entry.key).text = entry.value;
      }
      _initialised = true;
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Bu bilgiler yapay zekâya gönderilen bağlam dosyasına '
                    'girer. Ne kadar doldurursan plan o kadar sana göre '
                    'olur; boş bıraktıkların "belirtilmedi" diye geçer.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        for (final (key, label, hint) in ProfileKeys.form)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: TextField(
              key: Key('field-$key'),
              controller: _controllerFor(key),
              keyboardType: _keyboardFor(key),
              textCapitalization: TextCapitalization.sentences,
              maxLines: key == ProfileKeys.healthConstraints ? 2 : 1,
              decoration: InputDecoration(
                labelText: key == ProfileKeys.heightCm ? '$label *' : label,
                hintText: hint.isEmpty ? null : hint,
                suffixText: _suffixFor(key),
              ),
            ),
          ),

        const SizedBox(height: AppSpacing.sm),
        FilledButton(
          key: const Key('save-profile-button'),
          onPressed: _saving ? null : _save,
          child: Text(widget.saveLabel),
        ),
        if (widget.trailing.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl3),
          ...widget.trailing,
        ],
        const SizedBox(height: AppSpacing.xl4),
      ],
    );
  }

  TextInputType _keyboardFor(String key) => switch (key) {
    ProfileKeys.age ||
    ProfileKeys.heightCm => TextInputType.number,
    ProfileKeys.currentWeightKg ||
    ProfileKeys.targetWeightKg => const TextInputType.numberWithOptions(
      decimal: true,
    ),
    _ => TextInputType.text,
  };

  String? _suffixFor(String key) => switch (key) {
    ProfileKeys.heightCm => 'cm',
    ProfileKeys.currentWeightKg || ProfileKeys.targetWeightKg => 'kg',
    _ => null,
  };
}
