import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController with ChangeNotifier {
  static const String _prefsKey = 'app_settings_json_v1';

  final SharedPreferences _prefs;
  Settings _settings;

  SettingsController._(this._prefs, this._settings);

  static Future<SettingsController> load() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_prefsKey);
    Settings settings = const Settings();

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        settings = Settings.fromJson(Map<String, dynamic>.from(decoded as Map));
      } catch (_) {
        settings = const Settings();
      }
    }

    return SettingsController._(prefs, settings);
  }

  Settings get settings => _settings;

  void update(Settings newSettings) {
    _settings = newSettings;
    notifyListeners();

    final raw = jsonEncode(newSettings.toJson());
    unawaited(_prefs.setString(_prefsKey, raw));
  }
}

class Settings {
  static const Object _noChange = Object();
  static const List<String> _defaultNavBarOrder = [
    'page1',
    'page2',
    'page3',
    'page4',
    'page5',
    'page6',
  ];

  final bool useSystemDarkmode;
  final bool useDarkmode;
  final bool useSystemTextScaling;
  final bool didCompleteOnboarding;
  final String? localeCode;
  final List<String> navBarItemOrder;
  final List<String> hiddenNavBarItems;

  const Settings({
    this.useSystemDarkmode = true,
    this.useDarkmode = false,
    this.useSystemTextScaling = false,
    this.didCompleteOnboarding = false,
    this.localeCode,
    this.navBarItemOrder = _defaultNavBarOrder,
    this.hiddenNavBarItems = const [],
  });

  Settings copyWith({
    bool? useSystemDarkmode,
    bool? useDarkmode,
    bool? useSystemTextScaling,
    bool? didCompleteOnboarding,
    Object? localeCode = _noChange,
    List<String>? navBarItemOrder,
    List<String>? hiddenNavBarItems,
  }) {
    return Settings(
      useSystemDarkmode: useSystemDarkmode ?? this.useSystemDarkmode,
      useDarkmode: useDarkmode ?? this.useDarkmode,
      useSystemTextScaling: useSystemTextScaling ?? this.useSystemTextScaling,
      didCompleteOnboarding:
          didCompleteOnboarding ?? this.didCompleteOnboarding,
      localeCode: identical(localeCode, _noChange)
          ? this.localeCode
          : localeCode as String?,
      navBarItemOrder: navBarItemOrder ?? this.navBarItemOrder,
      hiddenNavBarItems: hiddenNavBarItems ?? this.hiddenNavBarItems,
    );
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      useSystemDarkmode: json['useSystemDarkmode'] ?? true,
      useDarkmode: json['useDarkmode'] ?? false,
      useSystemTextScaling: json['useSystemTextScaling'] ?? false,
      didCompleteOnboarding: json['didCompleteOnboarding'] ?? false,
      localeCode: json['localeCode'],
      navBarItemOrder: (json['navBarItemOrder'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          _defaultNavBarOrder,
      hiddenNavBarItems: (json['hiddenNavBarItems'] as List<dynamic>?)
              ?.whereType<String>()
              .where((item) => item != 'page6')
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'useSystemDarkmode': useSystemDarkmode,
      'useDarkmode': useDarkmode,
      'useSystemTextScaling': useSystemTextScaling,
      'didCompleteOnboarding': didCompleteOnboarding,
      'localeCode': localeCode,
      'navBarItemOrder': navBarItemOrder,
      'hiddenNavBarItems':
          hiddenNavBarItems.where((item) => item != 'page6').toList(),
    };
  }
}
