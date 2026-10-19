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
  final String? sectionId;
  final String registrationId;
  final String? instanceId;
  final Map<String, dynamic> parameters;
  final String? title;
  final bool isDirty;
  final String? destinationId;
  final String? contextId;
  final String? moduleId;
  final bool? inspectorOpen;
  final bool? splitOpen;

  const ShellTabPreference({
    required this.id,
    required this.registrationId,
    this.sectionId,
    this.instanceId,
    this.parameters = const {},
    this.title,
    this.isDirty = false,
    this.destinationId,
    this.contextId,
    this.moduleId,
    this.inspectorOpen,
    this.splitOpen,
  });

  ShellTabPreference copyWith({
    Object? sectionId = _noChange,
    String? instanceId,
    Map<String, dynamic>? parameters,
    Object? title = _noChange,
    bool? isDirty,
    Object? destinationId = _noChange,
    Object? contextId = _noChange,
    Object? moduleId = _noChange,
    Object? inspectorOpen = _noChange,
    Object? splitOpen = _noChange,
  }) {
    return ShellTabPreference(
      id: id,
      registrationId: registrationId,
      sectionId: identical(sectionId, _noChange) ? this.sectionId : sectionId as String?,
      instanceId: instanceId ?? this.instanceId,
      parameters: parameters ?? this.parameters,
      title: identical(title, _noChange) ? this.title : title as String?,
      isDirty: isDirty ?? this.isDirty,
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
      sectionId: json['sectionId'] is String ? json['sectionId'] as String : null,
      instanceId: json['instanceId'] is String ? json['instanceId'] as String : null,
      parameters: json['parameters'] is Map ? Map<String, dynamic>.from(json['parameters'] as Map) : const {},
      title: json['title'] is String ? json['title'] as String : null,
      isDirty: json['isDirty'] == true,
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
    if (sectionId != null) 'sectionId': sectionId,
    if (instanceId != null) 'instanceId': instanceId,
    if (parameters.isNotEmpty) 'parameters': parameters,
    if (title != null) 'title': title,
    if (isDirty) 'isDirty': true,
    if (destinationId != null) 'destinationId': destinationId,
    if (contextId != null) 'contextId': contextId,
    if (moduleId != null) 'moduleId': moduleId,
    if (inspectorOpen != null) 'inspectorOpen': inspectorOpen,
    if (splitOpen != null) 'splitOpen': splitOpen,
  };
}

class ShellWorkspacePreference {
  final String sectionId;
  final List<ShellTabPreference> tabs;
  final String? activeTabId;
  final bool? inspectorOpen;

  const ShellWorkspacePreference({required this.sectionId, this.tabs = const [], this.activeTabId, this.inspectorOpen});

  factory ShellWorkspacePreference.fromJson(Map<String, dynamic> json) {
    final sectionId = json['sectionId'] as String;
    return ShellWorkspacePreference(
      sectionId: sectionId,
      tabs: _readShellTabs(json['tabs'], sectionId: sectionId),
      activeTabId: json['activeTabId'] is String ? json['activeTabId'] as String : null,
      inspectorOpen: json['inspectorOpen'] is bool ? json['inspectorOpen'] as bool : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'sectionId': sectionId,
    'tabs': tabs.map((tab) => tab.toJson()).toList(),
    'activeTabId': activeTabId,
    if (inspectorOpen != null) 'inspectorOpen': inspectorOpen,
  };
}

List<ShellTabPreference> _readShellTabs(Object? value, {String? sectionId}) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) {
        final id = item['id'];
        final registrationId = item['registrationId'];
        if (id is! String || registrationId is! String) return null;
        if (!Settings.isStableId(id, maxLength: 256) || !Settings.isStableId(registrationId, maxLength: 128)) {
          return null;
        }
        final tab = ShellTabPreference.fromJson(Map<String, dynamic>.from(item));
        return sectionId == null ? tab : tab.copyWith(sectionId: sectionId);
      })
      .whereType<ShellTabPreference>()
      .toList();
}

class Settings {
  static const Object _noChange = Object();
  static const List<String> _defaultNavBarOrder = ['page1', 'page2', 'page3', 'page4', 'page5', 'page6'];
  static const List<ShellTabPreference> _defaultTabs = [];

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
  final List<ShellWorkspacePreference> shellWorkspaces;
  final String selectedShellTabId;
  final String? selectedActivityId;
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
    this.shellWorkspaces = const [],
    this.selectedShellTabId = '',
    this.selectedActivityId,
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
    List<ShellWorkspacePreference>? shellWorkspaces,
    String? selectedShellTabId,
    Object? selectedActivityId = _noChange,
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
      shellWorkspaces: shellWorkspaces ?? this.shellWorkspaces,
      selectedShellTabId: selectedShellTabId ?? this.selectedShellTabId,
      selectedActivityId: identical(selectedActivityId, _noChange)
          ? this.selectedActivityId
          : selectedActivityId as String?,
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
      'shellWorkspaces',
      'selectedShellTabId',
      'selectedActivityId',
      'selectedContextId',
      'selectedModuleId',
    };
    final tabs = _readShellTabs(json['shellTabs']);
    final workspaceJson = json['shellWorkspaces'];
    final workspaces = workspaceJson is List
        ? workspaceJson
              .whereType<Map>()
              .map((item) {
                final sectionId = item['sectionId'];
                if (sectionId is! String || !isStableId(sectionId, maxLength: 128)) return null;
                return ShellWorkspacePreference.fromJson(Map<String, dynamic>.from(item));
              })
              .whereType<ShellWorkspacePreference>()
              .toList()
        : const <ShellWorkspacePreference>[];
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
      shellWorkspaces: workspaces,
      selectedShellTabId: json['selectedShellTabId'] is String ? json['selectedShellTabId'] as String : '',
      selectedActivityId: json['selectedActivityId'] is String ? json['selectedActivityId'] as String : null,
      selectedContextId: json['selectedContextId'] is String ? json['selectedContextId'] as String : null,
      selectedModuleId: json['selectedModuleId'] is String ? json['selectedModuleId'] as String : null,
      extraSettings: Map.fromEntries(json.entries.where((entry) => !knownKeys.contains(entry.key))),
    );
  }

  static bool isStableId(String value, {required int maxLength}) =>
      value.isNotEmpty &&
      value.length <= maxLength &&
      value.trim() == value &&
      !RegExp(r'[\u0000-\u001F]').hasMatch(value);

  Map<String, dynamic> toJson() {
    return {
      ...extraSettings,
      'schemaVersion': 6,
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
      'shellWorkspaces': shellWorkspaces.map((workspace) => workspace.toJson()).toList(),
      'selectedShellTabId': selectedShellTabId,
      'selectedActivityId': selectedActivityId,
      'selectedContextId': selectedContextId,
      'selectedModuleId': selectedModuleId,
    };
  }
}
