import 'package:disport/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:disport/l10n/app_localizations.dart';

/// Çevrilmiş metinlere kısa erişim: `context.l10n.tabToday`.
///
/// `AppLocalizations.of(context)` her çağrı yerinde uzun duruyor ve
/// widget kodunu gürültüye boğuyor. `context.semantic` ile aynı desen.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
