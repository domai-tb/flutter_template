import 'package:flutter/widgets.dart';

import 'package:mobile_app_skeleton/l10n/l10n.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

