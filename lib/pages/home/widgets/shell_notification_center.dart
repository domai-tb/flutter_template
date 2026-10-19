import 'package:flutter/material.dart';

import 'package:flutter_template/core/shell_notifications.dart';
import 'package:flutter_template/l10n/l10n_x.dart';

Future<void> showShellNotifications(
  BuildContext context,
  ShellNotificationService service, {
  required bool phone,
}) async {
  final panel = _NotificationPanel(service: service);
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

class _NotificationPanel extends StatelessWidget {
  final ShellNotificationService service;

  const _NotificationPanel({required this.service});

  @override
  Widget build(BuildContext context) {
    final phone = MediaQuery.sizeOf(context).width < 600;
    return SizedBox(
      width: phone ? double.infinity : 440,
      height: phone ? double.infinity : 480,
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
