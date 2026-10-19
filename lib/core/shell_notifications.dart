import 'package:flutter/foundation.dart';

enum ShellNotificationSeverity { info, success, warning, error }

@immutable
class ShellNotification {
  final String id;
  final DateTime time;
  final ShellNotificationSeverity severity;
  final String title;
  final String? message;
  final String? contextId;
  final VoidCallback? onAction;
  final bool isRead;

  const ShellNotification({
    required this.id,
    required this.time,
    required this.severity,
    required this.title,
    this.message,
    this.contextId,
    this.onAction,
    this.isRead = false,
  });

  ShellNotification copyWith({bool? isRead}) => ShellNotification(
    id: id,
    time: time,
    severity: severity,
    title: title,
    message: message,
    contextId: contextId,
    onAction: onAction,
    isRead: isRead ?? this.isRead,
  );
}

class ShellNotificationService extends ChangeNotifier {
  static const int capacity = 100;
  final List<ShellNotification> _notifications = [];
  int _nextId = 0;

  List<ShellNotification> get notifications => List.unmodifiable(_notifications.reversed);
  int get unreadCount => _notifications.where((item) => !item.isRead).length;

  String add({
    required ShellNotificationSeverity severity,
    required String title,
    String? message,
    String? contextId,
    VoidCallback? onAction,
  }) {
    final id = 'shell-${DateTime.now().microsecondsSinceEpoch}-${_nextId++}';
    _notifications.add(
      ShellNotification(
        id: id,
        time: DateTime.now(),
        severity: severity,
        title: title,
        message: message,
        contextId: contextId,
        onAction: onAction,
      ),
    );
    while (_notifications.length > capacity) {
      final oldestRead = _notifications.indexWhere((item) => item.isRead);
      _notifications.removeAt(oldestRead < 0 ? 0 : oldestRead);
    }
    notifyListeners();
    return id;
  }

  void markRead(String id) => _update(id, (item) => item.copyWith(isRead: true));

  void markAllRead() {
    if (unreadCount == 0) return;
    for (var index = 0; index < _notifications.length; index++) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
    notifyListeners();
  }

  void dismiss(String id) {
    if (!_notifications.any((item) => item.id == id)) return;
    _notifications.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clear() {
    if (_notifications.isEmpty) return;
    _notifications.clear();
    notifyListeners();
  }

  void runAction(String id) {
    final item = _notifications.where((notification) => notification.id == id).firstOrNull;
    item?.onAction?.call();
    if (item != null) markRead(id);
  }

  void _update(String id, ShellNotification Function(ShellNotification) update) {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index < 0 || _notifications[index].isRead) return;
    _notifications[index] = update(_notifications[index]);
    notifyListeners();
  }
}
