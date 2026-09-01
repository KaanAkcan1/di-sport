import 'dart:async';

import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/today/application/day_providers.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Günün serbest notu.
///
/// "Bunu yedim", "şınavda zorlandım" gibi cümleler. M4'te `context.md`'ye
/// **düzenlenmeden** aktarılır (spec 7.1, "Kendi sözlerin"): AI'ın en
/// değerli girdisi kullanıcının kendi ifadesidir, özetlenmiş hali değil.
class DayNoteField extends ConsumerStatefulWidget {
  const DayNoteField({super.key});

  @override
  ConsumerState<DayNoteField> createState() => _DayNoteFieldState();
}

class _DayNoteFieldState extends ConsumerState<DayNoteField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  var _initialised = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Her tuşta veritabanına yazmak yerine yazma durunca kaydet.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      ref
          .read(todayRepositoryProvider)
          .setNote(ref.read(viewedDateProvider), value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final log = ref.watch(dayLogProvider(ref.watch(viewedDateProvider))).value;

    // Kaydedilmiş notu bir kez alana yaz. Sürekli senkronlarsak
    // kullanıcı yazarken imleç başa atlar.
    if (!_initialised && log != null) {
      _controller.text = log.note;
      _initialised = true;
    }

    return AppSection(
      title: context.l10n.todayNoteTitle,
      description: context.l10n.todayNoteDescription,
      padding: EdgeInsets.zero,
      child: TextField(
        key: const Key('day-note-field'),
        controller: _controller,
        focusNode: _focusNode,
        maxLines: 4,
        minLines: 3,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: context.l10n.todayNoteHint,
          contentPadding: const EdgeInsets.all(AppSpacing.lg),
        ),
        onChanged: _onChanged,
        // Odak kaybında beklemeden yaz: kullanıcı sekme değiştirirse
        // son yazdığı cümle kaybolmasın.
        onTapOutside: (_) {
          _debounce?.cancel();
          ref
              .read(todayRepositoryProvider)
              .setNote(ref.read(viewedDateProvider), _controller.text);
          _focusNode.unfocus();
        },
      ),
    );
  }
}
