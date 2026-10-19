import 'package:flutter/material.dart';

import 'package:flutter_template/core/shell_notifications.dart';
import 'package:flutter_template/l10n/l10n_x.dart';

Future<void> showShellNotifications(
  BuildContext context,
  ShellNotificationService service, {
  required bool phone,
}) async {
  final panel = _NotificationPanel(service: service, phone: phone);
  if (phone) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(height: MediaQuery.sizeOf(context).height * 0.8, child: panel),
      ),
    );
  } else {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(child: panel),
    );
  }
}

class ShellNotificationsAction extends StatelessWidget {
  final ShellNotificationService service;
  final bool phone;

  const ShellNotificationsAction({super.key, required this.service, required this.phone});

  @override
  Widget build(BuildContext context) {
    Widget button(VoidCallback? onPressed) => AnimatedBuilder(
      animation: service,
      builder: (context, _) => IconButton(
        tooltip: context.l10n.openNotifications,
        onPressed: onPressed,
        icon: Badge(
          isLabelVisible: service.unreadCount > 0,
          label: Text(service.unreadCount > 99 ? '99+' : '${service.unreadCount}'),
          child: const Icon(Icons.notifications_none),
        ),
      ),
    );

    if (phone) return button(() => showShellNotifications(context, service, phone: true));
    return MenuAnchor(
      crossAxisUnconstrained: false,
      style: const MenuStyle(
        minimumSize: WidgetStatePropertyAll(Size(360, 0)),
        maximumSize: WidgetStatePropertyAll(Size(420, 440)),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        SizedBox(
          key: const ValueKey('notifications-popover'),
          width: 360,
          height: 400,
          child: _NotificationPanel(service: service, phone: false),
        ),
      ],
      builder: (context, controller, _) => button(() => controller.isOpen ? controller.close() : controller.open()),
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  final ShellNotificationService service;
  final bool phone;

  const _NotificationPanel({required this.service, required this.phone});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: phone ? double.infinity : 360,
      height: phone ? double.infinity : 400,
      child: AnimatedBuilder(
        animation: service,
        builder: (context, _) => Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, phone ? 8 : 12, 8, 8),
              child: Row(
                children: [
                  Expanded(child: Text(context.l10n.notifications, style: Theme.of(context).textTheme.titleMedium)),
                  IconButton(
                    tooltip: context.l10n.markAllRead,
                    onPressed: service.unreadCount == 0 ? null : service.markAllRead,
                    icon: const Icon(Icons.done_all),
                  ),
                  IconButton(
                    tooltip: context.l10n.clearNotifications,
                    onPressed: service.notifications.isEmpty ? null : service.clear,
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: service.notifications.isEmpty
                  ? Center(child: Text(context.l10n.noNotifications))
                  : ListView.builder(
                      itemCount: service.notifications.length,
                      itemBuilder: (context, index) {
                        final item = service.notifications[index];
                        final severity = _severityLabel(context, item.severity);
                        final detail = [?item.message, ?item.contextId].join(' · ');
                        return Semantics(
                          label: '$severity: ${item.title}',
                          child: ListTile(
                            dense: !phone,
                            leading: Icon(_severityIcon(item.severity), color: _severityColor(context, item.severity)),
                            title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: detail.isEmpty
                                ? null
                                : Text(detail, maxLines: 3, overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              tooltip: context.l10n.dismissNotification,
                              onPressed: () => service.dismiss(item.id),
                              icon: const Icon(Icons.close),
                            ),
                            onTap: () {
                              if (item.onAction != null) {
                                service.runAction(item.id);
                              } else {
                                service.markRead(item.id);
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _severityLabel(BuildContext context, ShellNotificationSeverity severity) => switch (severity) {
    ShellNotificationSeverity.info => context.l10n.notificationInfo,
    ShellNotificationSeverity.success => context.l10n.notificationSuccess,
    ShellNotificationSeverity.warning => context.l10n.notificationWarning,
    ShellNotificationSeverity.error => context.l10n.notificationError,
  };

  IconData _severityIcon(ShellNotificationSeverity severity) => switch (severity) {
    ShellNotificationSeverity.info => Icons.info_outline,
    ShellNotificationSeverity.success => Icons.check_circle_outline,
    ShellNotificationSeverity.warning => Icons.warning_amber_outlined,
    ShellNotificationSeverity.error => Icons.error_outline,
  };

  Color _severityColor(BuildContext context, ShellNotificationSeverity severity) => switch (severity) {
    ShellNotificationSeverity.info => Theme.of(context).colorScheme.primary,
    ShellNotificationSeverity.success => Colors.green,
    ShellNotificationSeverity.warning => Colors.orange,
    ShellNotificationSeverity.error => Theme.of(context).colorScheme.error,
  };
}
