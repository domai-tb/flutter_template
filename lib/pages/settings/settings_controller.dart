import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_template/pages/settings/settings_entity.dart';
import 'package:flutter_template/pages/settings/settings_usecase.dart';

class SettingsController extends ChangeNotifier {
  final SettingsUseCase _useCase;
  Settings _settings;

  SettingsController._(this._useCase, this._settings);

  static Future<SettingsController> load(SettingsUseCase useCase) async =>
      SettingsController._(useCase, await useCase.load());

  Settings get settings => _settings;

  void update(Settings newSettings) {
    _settings = newSettings;
    notifyListeners();
    unawaited(_useCase.save(newSettings));
  }
}
