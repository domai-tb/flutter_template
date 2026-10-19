import 'package:flutter/widgets.dart';

import 'package:mobile_app_skeleton/core/app_services.dart';
import 'package:mobile_app_skeleton/core/settings.dart';

/// Lightweight app-wide scope that avoids external state-management packages.
class AppScope extends InheritedWidget {
  final SettingsController settings;
  final AppServices services;

  const AppScope({
    super.key,
    required this.settings,
    required this.services,
    required super.child,
  });

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AppScope oldWidget) {
    // Controllers are stable (created once in main).
    return settings != oldWidget.settings || services != oldWidget.services;
  }
}

