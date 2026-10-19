import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_template/core/settings.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';

class ShellNavigationCoordinator extends ChangeNotifier {
  ShellNavigationCoordinator({Iterable<ShellViewRegistration> views = const []}) {
    for (final view in views) {
      _views.putIfAbsent(view.id, () => view);
    }
  }

  final Map<String, ShellViewRegistration> _views = {};
  List<ShellTabPreference> _tabs = const [];
  String? _activeId;
  final List<String> _recentlyUsed = [];

  List<ShellTabPreference> get tabs => List.unmodifiable(_tabs);
  List<ShellViewRegistration> get views => List.unmodifiable(_views.values);
  String? get activeId => _activeId;
  ShellTabPreference? get activeTab => _tabs.where((tab) => tab.id == _activeId).firstOrNull;

  ShellViewRegistration? registrationFor(String id) => _views[id];

  void registerView(ShellViewRegistration view) {
    if (_views.containsKey(view.id)) throw ArgumentError.value(view.id, 'view.id', 'already registered');
    _views[view.id] = view;
    notifyListeners();
  }

  void unregisterView(String id) {
    if (_views.remove(id) == null) return;
    notifyListeners();
  }

  String? openView(
    String registrationId, {
    String? instanceId,
    Map<String, dynamic> parameters = const {},
    String? title,
  }) {
    final registration = _views[registrationId];
    if (registration == null || !registration.hasBuilder) return null;
    if (instanceId != null && instanceId.isEmpty) throw ArgumentError.value(instanceId, 'instanceId');
    final snapshot = Map<String, dynamic>.from(jsonDecode(jsonEncode(parameters)) as Map);
    final existing = _tabs.where(
      (tab) =>
          tab.registrationId == registrationId &&
          (instanceId != null && tab.instanceId == instanceId ||
              instanceId == null && registration.reusePolicy == ShellViewReusePolicy.byRegistration),
    );
    final tab = existing.firstOrNull;
    if (tab != null) {
      select(tab.id);
      return tab.id;
    }

    var index = 1;
    while (_tabs.any((tab) => tab.id == '$registrationId-$index')) {
      index++;
    }
    final next = ShellTabPreference(
      id: '$registrationId-$index',
      registrationId: registrationId,
      instanceId: instanceId,
      parameters: snapshot,
      title: title,
      destinationId: registration.destinationId,
      contextId: registration.contextId,
      moduleId: registration.moduleId,
    );
    _tabs = [..._tabs, next];
    _select(next.id);
    return next.id;
  }

  void restore(List<ShellTabPreference> tabs, String? activeId) {
    final unique = <ShellTabPreference>[];
    final seen = <String>{};
    for (final tab in tabs) {
      if (seen.add(tab.id)) unique.add(tab);
    }
    final nextActiveId = unique.any((tab) => tab.id == activeId) ? activeId : unique.firstOrNull?.id;
    if (_sameTabs(unique, _tabs) && nextActiveId == _activeId) return;
    _tabs = unique;
    _activeId = nextActiveId;
    _recentlyUsed
      ..clear()
      ..addAll([?nextActiveId, ...unique.reversed.map((tab) => tab.id).where((id) => id != nextActiveId)]);
    notifyListeners();
  }

  void select(String id) {
    if (_tabs.any((tab) => tab.id == id)) _select(id);
  }

  void updateTab(ShellTabPreference tab) {
    final index = _tabs.indexWhere((item) => item.id == tab.id);
    if (index < 0) return;
    _tabs = [..._tabs]..[index] = tab;
    notifyListeners();
  }

  void close(String id, {required bool closable}) {
    if (!closable) return;
    final index = _tabs.indexWhere((tab) => tab.id == id);
    if (index < 0) return;
    _tabs = [..._tabs]..removeAt(index);
    _recentlyUsed.remove(id);
    if (_activeId == id) {
      _activeId = _recentlyUsed.where((candidate) => _tabs.any((tab) => tab.id == candidate)).firstOrNull;
      if (_activeId == null && _tabs.isNotEmpty) _activeId = _tabs[index.clamp(0, _tabs.length - 1)].id;
      if (_activeId != null) _touch(_activeId!);
    }
    notifyListeners();
  }

  void closeOthers(String id, {required bool Function(String id) canClose}) {
    _tabs = _tabs.where((tab) => tab.id == id || !canClose(tab.id)).toList();
    _recentlyUsed.removeWhere((candidate) => !_tabs.any((tab) => tab.id == candidate));
    if (_tabs.any((tab) => tab.id == id)) {
      _activeId = id;
      _touch(id);
    } else if (!_tabs.any((tab) => tab.id == _activeId)) {
      _activeId = _tabs.firstOrNull?.id;
    }
    notifyListeners();
  }

  void closeRight(String id, {required bool Function(String id) canClose}) {
    final index = _tabs.indexWhere((tab) => tab.id == id);
    if (index < 0) return;
    final removed = _tabs.skip(index + 1).where((tab) => canClose(tab.id)).map((tab) => tab.id).toSet();
    if (removed.isEmpty) return;
    _tabs = _tabs.where((tab) => !removed.contains(tab.id)).toList();
    _recentlyUsed.removeWhere(removed.contains);
    if (!_tabs.any((tab) => tab.id == _activeId)) _activeId = id;
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _tabs.length || newIndex < 0 || newIndex >= _tabs.length || oldIndex == newIndex) {
      return;
    }
    final tabs = [..._tabs];
    final tab = tabs.removeAt(oldIndex);
    tabs.insert(newIndex, tab);
    _tabs = tabs;
    notifyListeners();
  }

  void move(String id, int offset) {
    final index = _tabs.indexWhere((tab) => tab.id == id);
    final target = index + offset;
    if (index < 0 || target < 0 || target >= _tabs.length) return;
    reorder(index, target);
  }

  void _select(String id) {
    _activeId = id;
    _touch(id);
    notifyListeners();
  }

  void _touch(String id) {
    _recentlyUsed.remove(id);
    _recentlyUsed.insert(0, id);
  }

  bool _sameTabs(List<ShellTabPreference> left, List<ShellTabPreference> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      final a = left[index];
      final b = right[index];
      if (a.id != b.id ||
          a.registrationId != b.registrationId ||
          a.instanceId != b.instanceId ||
          jsonEncode(a.parameters) != jsonEncode(b.parameters) ||
          a.title != b.title ||
          a.isDirty != b.isDirty ||
          a.destinationId != b.destinationId ||
          a.contextId != b.contextId ||
          a.moduleId != b.moduleId ||
          a.inspectorOpen != b.inspectorOpen ||
          a.splitOpen != b.splitOpen) {
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
