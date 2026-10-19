import 'package:flutter/foundation.dart';

import 'package:flutter_template/core/settings.dart';

class ShellNavigationCoordinator extends ChangeNotifier {
  List<ShellTabPreference> _tabs = const [];
  String? _activeId;
  final List<String> _recentlyUsed = [];

  List<ShellTabPreference> get tabs => List.unmodifiable(_tabs);
  String? get activeId => _activeId;
  ShellTabPreference? get activeTab => _tabs.where((tab) => tab.id == _activeId).firstOrNull;

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

  void open(ShellTabPreference tab, {bool reuseRegistration = false}) {
    final existing =
        _tabs.where((item) => item.id == tab.id).firstOrNull ??
        (reuseRegistration ? _tabs.where((item) => item.registrationId == tab.registrationId).firstOrNull : null);
    if (existing != null) {
      select(existing.id);
      return;
    }
    _tabs = [..._tabs, tab];
    _select(tab.id);
  }

  void select(String id) {
    if (_tabs.any((tab) => tab.id == id)) _select(id);
  }

  void updateActive(ShellTabPreference tab) {
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
