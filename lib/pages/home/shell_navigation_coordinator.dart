import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_template/core/settings.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';

class ShellSectionWorkspace {
  final String sectionId;
  final List<ShellTabPreference> tabs;
  final String? activeTabId;
  final bool? inspectorOpen;

  ShellSectionWorkspace({
    required this.sectionId,
    List<ShellTabPreference> tabs = const [],
    this.activeTabId,
    this.inspectorOpen,
  }) : tabs = List.unmodifiable(tabs);

  ShellTabPreference? get activeTab => tabs.where((tab) => tab.id == activeTabId).firstOrNull;

  ShellWorkspacePreference toPreference() => ShellWorkspacePreference(
    sectionId: sectionId,
    tabs: tabs,
    activeTabId: activeTabId,
    inspectorOpen: inspectorOpen,
  );
}

class ShellNavigationCoordinator extends ChangeNotifier {
  ShellNavigationCoordinator({
    Iterable<ShellDestination> sections = const [],
    Iterable<ShellViewRegistration> views = const [],
  }) {
    for (final section in sections) {
      _sections[section.id] = section;
      _workspaces[section.id] = ShellSectionWorkspace(sectionId: section.id);
    }
    for (final view in views) {
      _views.putIfAbsent(view.id, () => view);
    }
    _selectedSectionId = _sections.keys.firstOrNull;
  }

  final Map<String, ShellDestination> _sections = {};
  final Map<String, ShellViewRegistration> _views = {};
  final Map<String, ShellSectionWorkspace> _workspaces = {};
  final Map<String, List<String>> _recentlyUsed = {};
  String? _selectedSectionId;

  List<ShellDestination> get sections => List.unmodifiable(_sections.values);
  List<ShellViewRegistration> get views => List.unmodifiable(_views.values);
  List<ShellSectionWorkspace> get workspaces => List.unmodifiable(_workspaces.values);
  String? get selectedSectionId => _selectedSectionId;
  ShellSectionWorkspace get activeWorkspace => workspaceFor(_selectedSectionId ?? '');
  List<ShellTabPreference> get tabs => activeWorkspace.tabs;
  List<ShellTabPreference> get allTabs => List.unmodifiable(_workspaces.values.expand((workspace) => workspace.tabs));
  String? get activeId => activeWorkspace.activeTabId;
  ShellTabPreference? get activeTab => activeWorkspace.activeTab;

  ShellDestination? sectionFor(String id) => _sections[id];

  ShellSectionWorkspace workspaceFor(String sectionId) =>
      _workspaces[sectionId] ?? ShellSectionWorkspace(sectionId: sectionId);

  ShellSectionWorkspace getWorkspace(String sectionId) => workspaceFor(sectionId);

  ShellTabPreference? getActiveTab(String sectionId) => workspaceFor(sectionId).activeTab;

  ShellViewRegistration? registrationFor(String id) => _views[id];

  bool canOpenView(String sectionId, String registrationId) {
    final section = _sections[sectionId];
    final view = _views[registrationId];
    return section != null &&
        view?.hasBuilder == true &&
        (section.allowedViewIds == null || section.allowedViewIds!.contains(registrationId));
  }

  List<ShellViewRegistration> viewsForSection(String sectionId) =>
      List.unmodifiable(_views.values.where((view) => canOpenView(sectionId, view.id)));

  void registerSection(ShellDestination section) {
    if (_sections.containsKey(section.id)) throw ArgumentError.value(section.id, 'section.id', 'already registered');
    _sections[section.id] = section;
    _workspaces.putIfAbsent(section.id, () => ShellSectionWorkspace(sectionId: section.id));
    _selectedSectionId ??= section.id;
    notifyListeners();
  }

  void registerView(ShellViewRegistration view) {
    if (_views.containsKey(view.id)) throw ArgumentError.value(view.id, 'view.id', 'already registered');
    _views[view.id] = view;
    notifyListeners();
  }

  /// Removes a view registration only after its open tabs have been closed.
  bool unregisterView(String id) {
    if (!_views.containsKey(id) ||
        _workspaces.values.any((workspace) => workspace.tabs.any((tab) => tab.registrationId == id))) {
      return false;
    }
    _views.remove(id);
    notifyListeners();
    return true;
  }

  /// Removes an empty section and selects the next available section if needed.
  bool unregisterSection(String id) {
    final workspace = _workspaces[id];
    if (!_sections.containsKey(id) || workspace == null || workspace.tabs.isNotEmpty) return false;
    _sections.remove(id);
    _workspaces.remove(id);
    _recentlyUsed.remove(id);
    if (_selectedSectionId == id) _selectedSectionId = _sections.keys.firstOrNull;
    final selected = _selectedSectionId == null ? null : _sections[_selectedSectionId!];
    final defaultViewId = selected?.defaultViewId;
    if (selected != null && defaultViewId != null && canOpenView(selected.id, defaultViewId)) {
      openTab(selected.id, defaultViewId, activateSection: false);
    } else {
      notifyListeners();
    }
    return true;
  }

  void selectSection(String sectionId) {
    final section = _sections[sectionId];
    if (section == null) return;
    final changed = _selectedSectionId != sectionId;
    _selectedSectionId = sectionId;
    final workspace = workspaceFor(sectionId);
    final defaultViewId = section.defaultViewId;
    if (workspace.tabs.isEmpty && defaultViewId != null && canOpenView(sectionId, defaultViewId)) {
      openTab(sectionId, defaultViewId, activateSection: false);
    } else if (changed) {
      notifyListeners();
    }
  }

  String? openTab(
    String sectionId,
    String registrationId, {
    String? instanceId,
    Map<String, dynamic> parameters = const {},
    String? title,
    bool activateSection = true,
  }) {
    if (!canOpenView(sectionId, registrationId)) return null;
    final registration = _views[registrationId]!;
    if (instanceId != null && instanceId.isEmpty) throw ArgumentError.value(instanceId, 'instanceId');
    final snapshot = Map<String, dynamic>.from(jsonDecode(jsonEncode(parameters)) as Map);
    final workspace = workspaceFor(sectionId);
    final existing = switch (registration.reusePolicy) {
      ShellViewReusePolicy.never => null,
      ShellViewReusePolicy.byRegistration =>
        workspace.tabs.where((tab) => tab.registrationId == registrationId).firstOrNull,
      ShellViewReusePolicy.byInstance =>
        instanceId == null
            ? null
            : workspace.tabs
                  .where((tab) => tab.registrationId == registrationId && tab.instanceId == instanceId)
                  .firstOrNull,
    };
    if (existing != null) {
      selectTab(sectionId, existing.id, activateSection: activateSection);
      return existing.id;
    }

    var index = 1;
    String idFor(int value) => '$sectionId::$registrationId::$value';
    while (allTabs.any((tab) => tab.id == idFor(index))) {
      index++;
    }
    var resolvedInstanceId = instanceId ?? '$registrationId-$index';
    var duplicate = 1;
    while (workspace.tabs.any((tab) => tab.instanceId == resolvedInstanceId)) {
      duplicate++;
      resolvedInstanceId = '${instanceId ?? registrationId}-$duplicate';
    }
    final tab = ShellTabPreference(
      id: idFor(index),
      sectionId: sectionId,
      registrationId: registrationId,
      instanceId: resolvedInstanceId,
      parameters: snapshot,
      title: title,
      destinationId: registration.destinationId,
      contextId: registration.contextId,
      moduleId: registration.moduleId,
    );
    _setWorkspace(
      sectionId,
      ShellSectionWorkspace(
        sectionId: sectionId,
        tabs: [...workspace.tabs, tab],
        activeTabId: tab.id,
        inspectorOpen: workspace.inspectorOpen,
      ),
      activateSection: activateSection,
    );
    _touch(sectionId, tab.id);
    return tab.id;
  }

  String? openView(
    String registrationId, {
    String? sectionId,
    String? instanceId,
    Map<String, dynamic> parameters = const {},
    String? title,
    bool activateSection = true,
  }) {
    final target = sectionId ?? _views[registrationId]?.destinationId ?? _selectedSectionId;
    if (target == null) return null;
    return openTab(
      target,
      registrationId,
      instanceId: instanceId,
      parameters: parameters,
      title: title,
      activateSection: activateSection,
    );
  }

  void selectTab(String sectionId, String tabId, {bool activateSection = true}) {
    final workspace = workspaceFor(sectionId);
    if (!workspace.tabs.any((tab) => tab.id == tabId)) return;
    final sectionChanged = activateSection && _selectedSectionId != sectionId;
    if (workspace.activeTabId == tabId && !sectionChanged) return;
    _setWorkspace(
      sectionId,
      ShellSectionWorkspace(
        sectionId: sectionId,
        tabs: workspace.tabs,
        activeTabId: tabId,
        inspectorOpen: workspace.inspectorOpen,
      ),
      activateSection: activateSection,
    );
    _touch(sectionId, tabId);
  }

  void updateTabNavigationPath(String sectionId, String tabId, List<String> path) {
    final workspace = workspaceFor(sectionId);
    final index = workspace.tabs.indexWhere((tab) => tab.id == tabId);
    if (index < 0 || listEquals(workspace.tabs[index].navigationPath, path)) return;
    final tabs = List<ShellTabPreference>.of(workspace.tabs);
    tabs[index] = tabs[index].copyWith(navigationPath: path);
    _replaceWorkspace(
      ShellSectionWorkspace(
        sectionId: sectionId,
        tabs: tabs,
        activeTabId: workspace.activeTabId,
        inspectorOpen: workspace.inspectorOpen,
      ),
    );
  }

  void setSectionInspectorOpen(String sectionId, {required bool? isOpen}) {
    final workspace = workspaceFor(sectionId);
    if (workspace.inspectorOpen == isOpen) return;
    _replaceWorkspace(
      ShellSectionWorkspace(
        sectionId: sectionId,
        tabs: workspace.tabs,
        activeTabId: workspace.activeTabId,
        inspectorOpen: isOpen,
      ),
    );
  }

  void updateTab(ShellTabPreference tab) {
    final sectionId = tab.sectionId ?? _selectedSectionId;
    if (sectionId == null) return;
    final workspace = workspaceFor(sectionId);
    final index = workspace.tabs.indexWhere((item) => item.id == tab.id);
    if (index < 0) return;
    final tabs = [...workspace.tabs]..[index] = tab.copyWith(sectionId: sectionId);
    _replaceWorkspace(
      ShellSectionWorkspace(
        sectionId: sectionId,
        tabs: tabs,
        activeTabId: workspace.activeTabId,
        inspectorOpen: workspace.inspectorOpen,
      ),
    );
  }

  void closeTab(String sectionId, String tabId, {required bool closable}) {
    if (!closable) return;
    final workspace = workspaceFor(sectionId);
    final index = workspace.tabs.indexWhere((tab) => tab.id == tabId);
    if (index < 0) return;
    final tabs = [...workspace.tabs]..removeAt(index);
    final recent = _recentlyUsed.putIfAbsent(sectionId, () => []);
    recent.remove(tabId);
    var activeId = workspace.activeTabId;
    if (activeId == tabId) {
      activeId = recent.where((candidate) => tabs.any((tab) => tab.id == candidate)).firstOrNull;
      if (activeId == null && tabs.isNotEmpty) activeId = tabs[index.clamp(0, tabs.length - 1)].id;
      if (activeId != null) _touch(sectionId, activeId);
    }
    _replaceWorkspace(
      ShellSectionWorkspace(
        sectionId: sectionId,
        tabs: tabs,
        activeTabId: activeId,
        inspectorOpen: workspace.inspectorOpen,
      ),
    );
  }

  void closeOthers(String sectionId, String tabId, {required bool Function(String id) canClose}) {
    final workspace = workspaceFor(sectionId);
    final tabs = workspace.tabs.where((tab) => tab.id == tabId || !canClose(tab.id)).toList();
    final recent = _recentlyUsed.putIfAbsent(sectionId, () => []);
    recent.removeWhere((candidate) => !tabs.any((tab) => tab.id == candidate));
    final activeId = tabs.any((tab) => tab.id == tabId)
        ? tabId
        : tabs.any((tab) => tab.id == workspace.activeTabId)
        ? workspace.activeTabId
        : tabs.firstOrNull?.id;
    if (activeId != null) _touch(sectionId, activeId);
    _replaceWorkspace(
      ShellSectionWorkspace(
        sectionId: sectionId,
        tabs: tabs,
        activeTabId: activeId,
        inspectorOpen: workspace.inspectorOpen,
      ),
    );
  }

  void closeRight(String sectionId, String tabId, {required bool Function(String id) canClose}) {
    final workspace = workspaceFor(sectionId);
    final index = workspace.tabs.indexWhere((tab) => tab.id == tabId);
    if (index < 0) return;
    final removed = workspace.tabs.skip(index + 1).where((tab) => canClose(tab.id)).map((tab) => tab.id).toSet();
    if (removed.isEmpty) return;
    final tabs = workspace.tabs.where((tab) => !removed.contains(tab.id)).toList();
    _recentlyUsed.putIfAbsent(sectionId, () => []).removeWhere(removed.contains);
    final activeId = tabs.any((tab) => tab.id == workspace.activeTabId) ? workspace.activeTabId : tabId;
    _replaceWorkspace(
      ShellSectionWorkspace(
        sectionId: sectionId,
        tabs: tabs,
        activeTabId: activeId,
        inspectorOpen: workspace.inspectorOpen,
      ),
    );
  }

  void reorderTabs(String sectionId, int oldIndex, int newIndex) {
    final workspace = workspaceFor(sectionId);
    if (oldIndex < 0 || oldIndex >= workspace.tabs.length || newIndex < 0 || newIndex >= workspace.tabs.length) return;
    if (oldIndex == newIndex) return;
    final tabs = [...workspace.tabs];
    final tab = tabs.removeAt(oldIndex);
    tabs.insert(newIndex, tab);
    _replaceWorkspace(
      ShellSectionWorkspace(
        sectionId: sectionId,
        tabs: tabs,
        activeTabId: workspace.activeTabId,
        inspectorOpen: workspace.inspectorOpen,
      ),
    );
  }

  void moveTab(String sectionId, String tabId, int offset) {
    final tabs = workspaceFor(sectionId).tabs;
    final index = tabs.indexWhere((tab) => tab.id == tabId);
    final target = index + offset;
    if (index < 0 || target < 0 || target >= tabs.length) return;
    reorderTabs(sectionId, index, target);
  }

  void restoreWorkspaces(Iterable<ShellWorkspacePreference> preferences, {String? selectedSectionId}) {
    final next = <String, ShellSectionWorkspace>{
      for (final section in _sections.values) section.id: ShellSectionWorkspace(sectionId: section.id),
    };
    final seenTabs = <String>{};
    final seenSections = <String>{};
    final seenInstances = <String, Set<String>>{};
    for (final preference in preferences) {
      if (!seenSections.add(preference.sectionId)) continue;
      final sectionInstances = seenInstances.putIfAbsent(preference.sectionId, () => {});
      final tabs = <ShellTabPreference>[];
      for (final item in preference.tabs) {
        if (!seenTabs.add(item.id)) continue;
        final tab = item.sectionId == preference.sectionId ? item : item.copyWith(sectionId: preference.sectionId);
        var instanceId = tab.instanceId ?? 'restored-${tab.id}';
        var duplicate = 1;
        while (!sectionInstances.add(instanceId)) {
          duplicate++;
          instanceId = '${tab.instanceId ?? 'restored-${tab.id}'}-$duplicate';
        }
        tabs.add(tab.instanceId == instanceId ? tab : tab.copyWith(instanceId: instanceId));
      }
      final activeId = tabs.any((tab) => tab.id == preference.activeTabId)
          ? preference.activeTabId
          : tabs.firstOrNull?.id;
      next[preference.sectionId] = ShellSectionWorkspace(
        sectionId: preference.sectionId,
        tabs: tabs,
        activeTabId: activeId,
        inspectorOpen: preference.inspectorOpen,
      );
    }
    final activeSection = _sections.containsKey(selectedSectionId) ? selectedSectionId : _sections.keys.firstOrNull;
    if (_sameWorkspaces(next, _workspaces) && _selectedSectionId == activeSection) return;
    _workspaces
      ..clear()
      ..addAll(next);
    _selectedSectionId = activeSection;
    _recentlyUsed.clear();
    for (final workspace in _workspaces.values) {
      _recentlyUsed[workspace.sectionId] = [
        if (workspace.activeTabId != null) workspace.activeTabId!,
        ...workspace.tabs.reversed.map((tab) => tab.id).where((id) => id != workspace.activeTabId),
      ];
    }
    notifyListeners();
  }

  // Compatibility API for consumers migrating from the original flat workspace.
  void restore(List<ShellTabPreference> tabs, String? activeId) {
    final sectionId = _selectedSectionId ?? _sections.keys.firstOrNull;
    if (sectionId == null) return;
    restoreWorkspaces([
      ShellWorkspacePreference(
        sectionId: sectionId,
        tabs: tabs.map((tab) => tab.copyWith(sectionId: tab.sectionId ?? sectionId)).toList(),
        activeTabId: activeId,
      ),
    ], selectedSectionId: sectionId);
  }

  // Compatibility aliases operate on the selected section only.
  void select(String id) {
    final sectionId = _selectedSectionId;
    if (sectionId != null) selectTab(sectionId, id);
  }

  void close(String id, {required bool closable}) {
    final sectionId = workspaceContaining(id)?.sectionId;
    if (sectionId != null) closeTab(sectionId, id, closable: closable);
  }

  void reorder(int oldIndex, int newIndex) {
    final sectionId = _selectedSectionId;
    if (sectionId != null) reorderTabs(sectionId, oldIndex, newIndex);
  }

  void move(String id, int offset) {
    final sectionId = workspaceContaining(id)?.sectionId;
    if (sectionId != null) moveTab(sectionId, id, offset);
  }

  ShellSectionWorkspace? workspaceContaining(String tabId) =>
      _workspaces.values.where((workspace) => workspace.tabs.any((tab) => tab.id == tabId)).firstOrNull;

  void _setWorkspace(String sectionId, ShellSectionWorkspace workspace, {required bool activateSection}) {
    _workspaces[sectionId] = workspace;
    if (activateSection) _selectedSectionId = sectionId;
    notifyListeners();
  }

  void _replaceWorkspace(ShellSectionWorkspace workspace) {
    _workspaces[workspace.sectionId] = workspace;
    notifyListeners();
  }

  void _touch(String sectionId, String tabId) {
    final recent = _recentlyUsed.putIfAbsent(sectionId, () => []);
    recent.remove(tabId);
    recent.insert(0, tabId);
  }

  bool _sameWorkspaces(Map<String, ShellSectionWorkspace> left, Map<String, ShellSectionWorkspace> right) {
    if (left.length != right.length) return false;
    for (final entry in left.entries) {
      final other = right[entry.key];
      if (other == null ||
          entry.value.activeTabId != other.activeTabId ||
          entry.value.inspectorOpen != other.inspectorOpen ||
          jsonEncode(entry.value.tabs.map((tab) => tab.toJson()).toList()) !=
              jsonEncode(other.tabs.map((tab) => tab.toJson()).toList())) {
        return false;
      }
    }
    return true;
  }
}

class ShellWorkspace extends InheritedNotifier<ShellNavigationCoordinator> {
  const ShellWorkspace({super.key, required ShellNavigationCoordinator navigation, required super.child})
    : super(notifier: navigation);

  static ShellNavigationCoordinator of(BuildContext context) {
    final workspace = context.dependOnInheritedWidgetOfExactType<ShellWorkspace>();
    assert(workspace != null, 'ShellWorkspace not found in widget tree');
    return workspace!.notifier!;
  }
}
