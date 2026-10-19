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
    var settings = const Settings();

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          settings = Settings.fromJson(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        // Invalid local JSON falls back to defaults without deleting the saved value.
      }
    }
    return SettingsController._(prefs, settings);
  }

  Settings get settings => _settings;

  void update(Settings newSettings) {
    _settings = newSettings;
    notifyListeners();
    unawaited(_prefs.setString(_prefsKey, jsonEncode(newSettings.toJson())));
  }
}

class ShellTabPreference {
  static const Object _noChange = Object();

  final String id;
  final String registrationId;
  final String? destinationId;
  final String? contextId;
  final String? moduleId;
  final bool? inspectorOpen;
  final bool? splitOpen;

  const ShellTabPreference({
    required this.id,
    required this.registrationId,
    this.destinationId,
    this.contextId,
    this.moduleId,
    this.inspectorOpen,
    this.splitOpen,
  });

  ShellTabPreference copyWith({
    Object? destinationId = _noChange,
    Object? contextId = _noChange,
    Object? moduleId = _noChange,
    Object? inspectorOpen = _noChange,
    Object? splitOpen = _noChange,
  }) {
    return ShellTabPreference(
      id: id,
      registrationId: registrationId,
      destinationId: identical(destinationId, _noChange) ? this.destinationId : destinationId as String?,
      contextId: identical(contextId, _noChange) ? this.contextId : contextId as String?,
      moduleId: identical(moduleId, _noChange) ? this.moduleId : moduleId as String?,
      inspectorOpen: identical(inspectorOpen, _noChange) ? this.inspectorOpen : inspectorOpen as bool?,
      splitOpen: identical(splitOpen, _noChange) ? this.splitOpen : splitOpen as bool?,
    );
  }

  factory ShellTabPreference.fromJson(Map<String, dynamic> json) {
    return ShellTabPreference(
      id: json['id'] as String,
      registrationId: json['registrationId'] as String,
      destinationId: json['destinationId'] is String ? json['destinationId'] as String : null,
      contextId: json['contextId'] is String ? json['contextId'] as String : null,
      moduleId: json['moduleId'] is String ? json['moduleId'] as String : null,
      inspectorOpen: json['inspectorOpen'] is bool ? json['inspectorOpen'] as bool : null,
      splitOpen: json['splitOpen'] is bool ? json['splitOpen'] as bool : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'registrationId': registrationId,
    if (destinationId != null) 'destinationId': destinationId,
    if (contextId != null) 'contextId': contextId,
    if (moduleId != null) 'moduleId': moduleId,
    if (inspectorOpen != null) 'inspectorOpen': inspectorOpen,
    if (splitOpen != null) 'splitOpen': splitOpen,
  };
}

class Settings {
  static const Object _noChange = Object();
  static const List<String> _defaultNavBarOrder = ['page1', 'page2', 'page3', 'page4', 'page5', 'page6'];
  static const List<ShellTabPreference> _defaultTabs = [
    ShellTabPreference(id: 'page1', registrationId: 'page1', destinationId: 'page1'),
  ];

  final bool useSystemDarkmode;
  final bool useDarkmode;
  // Kept for migration compatibility. The app always honors OS text scaling.
  final bool useSystemTextScaling;
  final bool didCompleteOnboarding;
  final String? localeCode;
  final List<String> navBarItemOrder;
  final List<String> hiddenNavBarItems;
  final String accentPreset;
  final String density;
  final double inspectorWidth;
  final bool inspectorOpen;
  final double splitRatio;
  final bool splitOpen;
  final List<ShellTabPreference> shellTabs;
  final String selectedShellTabId;
  final String? selectedContextId;
  final String? selectedModuleId;
  final Map<String, dynamic> extraSettings;

  const Settings({
    this.useSystemDarkmode = false,
    this.useDarkmode = true,
    this.useSystemTextScaling = true,
    this.didCompleteOnboarding = false,
    this.localeCode,
    this.navBarItemOrder = _defaultNavBarOrder,
    this.hiddenNavBarItems = const [],
    this.accentPreset = 'steel',
    this.density = 'compact',
    this.inspectorWidth = 320,
    this.inspectorOpen = false,
    this.splitRatio = 0.5,
    this.splitOpen = false,
    this.shellTabs = _defaultTabs,
    this.selectedShellTabId = 'page1',
    this.selectedContextId,
    this.selectedModuleId,
    this.extraSettings = const {},
  });

  Settings copyWith({
    bool? useSystemDarkmode,
    bool? useDarkmode,
    bool? useSystemTextScaling,
    bool? didCompleteOnboarding,
    Object? localeCode = _noChange,
    List<String>? navBarItemOrder,
    List<String>? hiddenNavBarItems,
    String? accentPreset,
    String? density,
    double? inspectorWidth,
    bool? inspectorOpen,
    double? splitRatio,
    bool? splitOpen,
    List<ShellTabPreference>? shellTabs,
    String? selectedShellTabId,
    Object? selectedContextId = _noChange,
    Object? selectedModuleId = _noChange,
    Map<String, dynamic>? extraSettings,
  }) {
    return Settings(
      useSystemDarkmode: useSystemDarkmode ?? this.useSystemDarkmode,
      useDarkmode: useDarkmode ?? this.useDarkmode,
      useSystemTextScaling: useSystemTextScaling ?? this.useSystemTextScaling,
      didCompleteOnboarding: didCompleteOnboarding ?? this.didCompleteOnboarding,
      localeCode: identical(localeCode, _noChange) ? this.localeCode : localeCode as String?,
      navBarItemOrder: navBarItemOrder ?? this.navBarItemOrder,
      hiddenNavBarItems: hiddenNavBarItems ?? this.hiddenNavBarItems,
      accentPreset: accentPreset ?? this.accentPreset,
      density: density ?? this.density,
      inspectorWidth: inspectorWidth ?? this.inspectorWidth,
      inspectorOpen: inspectorOpen ?? this.inspectorOpen,
      splitRatio: splitRatio ?? this.splitRatio,
      splitOpen: splitOpen ?? this.splitOpen,
      shellTabs: shellTabs ?? this.shellTabs,
      selectedShellTabId: selectedShellTabId ?? this.selectedShellTabId,
      selectedContextId: identical(selectedContextId, _noChange)
          ? this.selectedContextId
          : selectedContextId as String?,
      selectedModuleId: identical(selectedModuleId, _noChange) ? this.selectedModuleId : selectedModuleId as String?,
      extraSettings: extraSettings ?? this.extraSettings,
    );
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    final knownKeys = {
      'schemaVersion',
      'useSystemDarkmode',
      'useDarkmode',
      'useSystemTextScaling',
      'didCompleteOnboarding',
      'localeCode',
      'navBarItemOrder',
      'hiddenNavBarItems',
      'accentPreset',
      'density',
      'inspectorWidth',
      'inspectorOpen',
      'splitRatio',
      'splitOpen',
      'shellTabs',
      'selectedShellTabId',
      'selectedContextId',
      'selectedModuleId',
    };
    final tabJson = json['shellTabs'];
    final tabs = tabJson is List
        ? tabJson
              .whereType<Map>()
              .map((item) {
                final id = item['id'];
                final registrationId = item['registrationId'];
                if (id is! String || registrationId is! String) return null;
                if (!RegExp(r'^[a-zA-Z0-9._-]{1,80}$').hasMatch(id) ||
                    !RegExp(r'^[a-zA-Z0-9._-]{1,80}$').hasMatch(registrationId)) {
                  return null;
                }
                return ShellTabPreference(id: id, registrationId: registrationId);
              })
              .whereType<ShellTabPreference>()
              .toList()
        : _defaultTabs;
    final width = json['inspectorWidth'];
    final ratio = json['splitRatio'];
    bool readBool(String key, {required bool fallback}) {
      final value = json[key];
      if (value is bool) return value;
      return fallback;
    }

    return Settings(
      useSystemDarkmode: readBool('useSystemDarkmode', fallback: false),
      useDarkmode: readBool('useDarkmode', fallback: true),
      useSystemTextScaling: readBool('useSystemTextScaling', fallback: true),
      didCompleteOnboarding: readBool('didCompleteOnboarding', fallback: false),
      localeCode: json['localeCode'] is String ? json['localeCode'] as String : null,
      navBarItemOrder: json['navBarItemOrder'] is List
          ? (json['navBarItemOrder'] as List).whereType<String>().toList()
          : _defaultNavBarOrder,
      hiddenNavBarItems: json['hiddenNavBarItems'] is List
          ? (json['hiddenNavBarItems'] as List).whereType<String>().where((item) => item != 'page6').toList()
          : const [],
      accentPreset: const {'steel', 'blue', 'green', 'violet'}.contains(json['accentPreset'])
          ? json['accentPreset'] as String
          : 'steel',
      density: const {'compact', 'comfortable'}.contains(json['density']) ? json['density'] as String : 'compact',
      inspectorWidth: width is num && width.isFinite ? width.toDouble().clamp(256, 440).toDouble() : 320,
      inspectorOpen: readBool('inspectorOpen', fallback: false),
      splitRatio: ratio is num && ratio.isFinite ? ratio.toDouble().clamp(0.3, 0.7) : 0.5,
      splitOpen: readBool('splitOpen', fallback: false),
      shellTabs: tabs,
      selectedShellTabId: json['selectedShellTabId'] is String ? json['selectedShellTabId'] as String : 'page1',
      selectedContextId: json['selectedContextId'] is String ? json['selectedContextId'] as String : null,
      selectedModuleId: json['selectedModuleId'] is String ? json['selectedModuleId'] as String : null,
      extraSettings: Map.fromEntries(json.entries.where((entry) => !knownKeys.contains(entry.key))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...extraSettings,
      'schemaVersion': 5,
      'useSystemDarkmode': useSystemDarkmode,
      'useDarkmode': useDarkmode,
      'useSystemTextScaling': useSystemTextScaling,
      'didCompleteOnboarding': didCompleteOnboarding,
      'localeCode': localeCode,
      'navBarItemOrder': navBarItemOrder,
      'hiddenNavBarItems': hiddenNavBarItems.where((item) => item != 'page6').toList(),
      'accentPreset': accentPreset,
      'density': density,
      'inspectorWidth': inspectorWidth.clamp(256, 440),
      'inspectorOpen': inspectorOpen,
      'splitRatio': splitRatio.clamp(0.3, 0.7),
      'splitOpen': splitOpen,
      'shellTabs': shellTabs.map((tab) => tab.toJson()).toList(),
      'selectedShellTabId': selectedShellTabId,
      'selectedContextId': selectedContextId,
      'selectedModuleId': selectedModuleId,
    };
  }
}
