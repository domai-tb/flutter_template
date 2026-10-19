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
    final metrics = AppTheme.metrics(context, phone: false);
    final railWidth = metrics.railWidth;
    final utilities = destinations.where((item) => item.isUtility).toList();

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
              padding: const EdgeInsets.only(top: AppShellSpacing.md),
              children: [
                for (final destination in destinations.where((item) => !item.isUtility)) _item(metrics, destination),
              ],
            ),
          ),
          if (utilities.isNotEmpty) Divider(height: 1, color: tokens?.border ?? theme.dividerColor),
          for (final destination in utilities) _item(metrics, destination),
        ],
      ),
    );
  }

  Widget _item(AppShellMetrics metrics, ShellDestination destination) => SizedBox(
    width: metrics.railWidth,
    height: metrics.activityRowHeight,
    child: _SideNavItem(
      key: ValueKey('activity-rail-${destination.id}'),
      destination: destination,
      selected: currentId == destination.id,
      iconSize: metrics.activityIconSize,
      onSelected: () => onSelected(destination.id),
    ),
  );
}

class _SideNavItem extends StatelessWidget {
  final ShellDestination destination;
  final bool selected;
  final double iconSize;
  final VoidCallback onSelected;

  const _SideNavItem({
    super.key,
    required this.destination,
    required this.selected,
    required this.iconSize,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppShellTokens>();
    final foreground = selected ? theme.colorScheme.primary : tokens?.textSecondary;
    final radius = tokens?.cornerRadius ?? 4;

    return Tooltip(
      message: destination.title(context),
      child: Semantics(
        button: true,
        selected: selected,
        label: destination.title(context),
        child: SizedBox(
          height: iconSize + AppShellSpacing.xl,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                left: 4,
                right: 4,
                child: Material(
                  color: selected
                      ? tokens?.selected ?? theme.colorScheme.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(radius),
                  child: InkWell(
                    onTap: onSelected,
                    borderRadius: BorderRadius.circular(radius),
                    hoverColor: tokens?.hover ?? theme.colorScheme.onSurface.withValues(alpha: 0.04),
                    focusColor:
                        tokens?.focus.withValues(alpha: 0.16) ?? theme.colorScheme.primary.withValues(alpha: 0.16),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              IgnorePointer(
                child: Icon(
                  selected ? destination.icon : destination.inactiveIcon ?? destination.icon,
                  size: iconSize,
                  color: foreground,
                ),
              ),
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
