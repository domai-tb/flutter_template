import 'package:flutter/material.dart';

import 'package:flutter_template/core/themes.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';

class SideNavBar extends StatelessWidget {
  final String currentId;
  final List<ShellDestination> destinations;
  final ValueChanged<String> onSelected;

  const SideNavBar({super.key, required this.currentId, required this.destinations, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppShellTokens>();
    final railWidth = tokens?.comfortable == true
        ? tokens!.desktopComfortable.railWidth
        : tokens?.desktopCompact.railWidth ?? AppShellMetrics.desktopCompact.railWidth;

    return Container(
      width: railWidth,
      decoration: BoxDecoration(
        color: tokens?.canvas ?? theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          for (final destination in destinations)
            Tooltip(
              message: destination.title(context),
              child: Semantics(
                button: true,
                selected: currentId == destination.id,
                label: destination.title(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    child: IconButton(
                      tooltip: destination.title(context),
                      onPressed: () => onSelected(destination.id),
                      style: IconButton.styleFrom(
                        foregroundColor: currentId == destination.id
                            ? theme.colorScheme.primary
                            : tokens?.textSecondary,
                        backgroundColor: currentId == destination.id
                            ? theme.colorScheme.primaryContainer
                            : Colors.transparent,
                      ),
                      icon: Icon(destination.icon, size: 22),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
