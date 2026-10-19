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
      key: const ValueKey('activity-rail'),
      width: railWidth,
      decoration: BoxDecoration(
        color: tokens?.canvas ?? theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              key: const ValueKey('activity-rail-sections'),
              padding: const EdgeInsets.only(top: 12),
              children: [
                for (final destination in destinations.where((item) => !item.isUtility)) _item(railWidth, destination),
              ],
            ),
          ),
          for (final destination in destinations.where((item) => item.isUtility)) ...[
            Divider(height: 1, color: theme.dividerColor),
            Padding(padding: const EdgeInsets.only(top: 6, bottom: 6), child: _item(railWidth, destination)),
          ],
        ],
      ),
    );
  }

  Widget _item(double railWidth, ShellDestination destination) => SizedBox(
    width: railWidth,
    height: 44,
    child: _SideNavItem(
      key: ValueKey('activity-rail-${destination.id}'),
      destination: destination,
      selected: currentId == destination.id,
      onSelected: () => onSelected(destination.id),
    ),
  );
}

class _SideNavItem extends StatelessWidget {
  final ShellDestination destination;
  final bool selected;
  final VoidCallback onSelected;

  const _SideNavItem({super.key, required this.destination, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppShellTokens>();
    final foreground = selected ? theme.colorScheme.primary : tokens?.textSecondary;

    return Tooltip(
      message: destination.title(context),
      child: Semantics(
        button: true,
        selected: selected,
        label: destination.title(context),
        child: SizedBox(
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                left: 4,
                right: 4,
                child: Material(
                  color: selected ? theme.colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  child: InkWell(
                    onTap: onSelected,
                    borderRadius: BorderRadius.circular(4),
                    hoverColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                    focusColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              IgnorePointer(child: Icon(destination.icon, size: 20, color: foreground)),
              if (selected)
                Positioned(
                  left: 0,
                  top: 14,
                  bottom: 14,
                  child: Container(
                    key: ValueKey('activity-rail-indicator-${destination.id}'),
                    width: 3,
                    decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
