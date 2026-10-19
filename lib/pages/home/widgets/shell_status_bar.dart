import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_template/l10n/l10n_x.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';

class ShellStatusBar extends StatelessWidget {
  final double height;
  final double menuRowHeight;
  final List<ShellNavigationNode> breadcrumbs;
  final List<ShellStatusItem> tabItems;
  final List<ShellStatusItem> sectionItems;
  final List<ShellStatusItem> globalItems;
  final FutureOr<void> Function(ShellNavigationNode node) onNavigate;
  final Widget notificationControl;

  const ShellStatusBar({
    super.key,
    required this.height,
    required this.menuRowHeight,
    required this.breadcrumbs,
    required this.tabItems,
    required this.sectionItems,
    required this.globalItems,
    required this.onNavigate,
    required this.notificationControl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontSize = theme.textTheme.labelSmall?.fontSize ?? 11;
    final barHeight = math.max(height, MediaQuery.textScalerOf(context).scale(fontSize) + 8);
    final tabs = _ordered(tabItems);
    final sections = _ordered(sectionItems);
    final globals = _ordered(globalItems);
    final items = [...tabs, ...sections, ...globals];
    final criticalGlobal = globals.where((item) => item.severity == ShellStatusSeverity.error).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        const notificationWidth = 30.0;
        const minBreadcrumbWidth = 160.0;
        const edgePadding = 8.0;
        final statusBudget = math.max(
          0,
          constraints.maxWidth - minBreadcrumbWidth - notificationWidth - 28 - edgePadding * 2,
        );
        final visible = <ShellStatusItem>{};
        var usedWidth = 0.0;
        void include(ShellStatusItem item) {
          if (visible.contains(item)) return;
          final itemWidth = _itemWidth(context, item);
          if (usedWidth + itemWidth <= statusBudget) {
            visible.add(item);
            usedWidth += itemWidth;
          }
        }

        for (final item in criticalGlobal) {
          include(item);
        }
        for (final item in items) {
          include(item);
        }
        final shown = items.where(visible.contains).toList();
        final overflow = items.where((item) => !visible.contains(item)).toList();

        return Container(
          key: const ValueKey('shell-status-bar'),
          height: barHeight,
          padding: const EdgeInsets.symmetric(horizontal: edgePadding),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ShellBreadcrumbBar(nodes: breadcrumbs, onNavigate: onNavigate),
              ),
              for (final item in shown) _StatusItemButton(item: item, width: _itemWidth(context, item)),
              if (overflow.isNotEmpty)
                PopupMenuButton<int>(
                  key: const ValueKey('status-overflow'),
                  tooltip: context.l10n.moreActions,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  iconSize: 16,
                  onSelected: (index) => _activateStatus(context, overflow[index]),
                  itemBuilder: (context) => [
                    for (var index = 0; index < overflow.length; index++)
                      PopupMenuItem(
                        value: index,
                        height: menuRowHeight,
                        child: Row(
                          children: [
                            if (overflow[index].icon case final icon?) ...[
                              Icon(icon, size: 16),
                              const SizedBox(width: 8),
                            ],
                            Flexible(child: Text(overflow[index].label, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                  ],
                  child: const SizedBox(width: 24, height: 24, child: Icon(Icons.more_horiz, size: 16)),
                ),
              SizedBox(width: notificationWidth, height: barHeight, child: notificationControl),
            ],
          ),
        );
      },
    );
  }

  List<ShellStatusItem> _ordered(List<ShellStatusItem> items) =>
      items..sort((left, right) => right.priority.compareTo(left.priority));

  double _itemWidth(BuildContext context, ShellStatusItem item) {
    final style = Theme.of(context).textTheme.labelSmall;
    final painter = TextPainter(
      text: TextSpan(text: item.label, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return painter.width.clamp(32.0, 104.0) + (item.icon == null ? 8 : 24) + (item.progress == null ? 0 : 28) + 8;
  }

  void _activateStatus(BuildContext context, ShellStatusItem item) {
    if (item.onTap case final action?) {
      action();
    } else if (item.detailsBuilder case final details?) {
      unawaited(
        showDialog<void>(
          context: context,
          builder: (context) => Dialog(child: details(context)),
        ),
      );
    }
  }
}

class _ShellBreadcrumbBar extends StatelessWidget {
  final List<ShellNavigationNode> nodes;
  final FutureOr<void> Function(ShellNavigationNode node) onNavigate;

  const _ShellBreadcrumbBar({required this.nodes, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final widths = nodes.map((node) => _nodeWidth(context, node)).toList();
        final fullWidth = widths.fold<double>(0, (sum, width) => sum + width) + (nodes.length - 1) * 12;
        final collapse = nodes.length > 3 && fullWidth > constraints.maxWidth;
        final visibleNodes = collapse ? [nodes.first, nodes[1], nodes.last] : nodes;
        final hiddenNodes = collapse ? nodes.sublist(2, nodes.length - 1) : const <ShellNavigationNode>[];
        final hasOverflow = hiddenNodes.isNotEmpty;
        return Row(
          children: [
            for (var index = 0; index < visibleNodes.length; index++) ...[
              if (index > 0) const Icon(Icons.chevron_right, size: 14),
              Flexible(
                child: _BreadcrumbSegment(
                  node: visibleNodes[index],
                  active: index == visibleNodes.length - 1,
                  onNavigate: onNavigate,
                ),
              ),
              if (index == 1 && hasOverflow) ...[
                const Icon(Icons.chevron_right, size: 14),
                _BreadcrumbMenuButton(
                  key: const ValueKey('breadcrumb-overflow'),
                  label: context.l10n.moreActions,
                  tooltip: context.l10n.moreActions,
                  icon: Icons.more_horiz,
                  loadNodes: () async => hiddenNodes,
                  onSelect: onNavigate,
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  double _nodeWidth(BuildContext context, ShellNavigationNode node) {
    final painter = TextPainter(
      text: TextSpan(text: node.label, style: Theme.of(context).textTheme.labelSmall),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return painter.width.clamp(36.0, 140.0) + (node.icon == null ? 0 : 18) + 16;
  }
}

class _BreadcrumbSegment extends StatefulWidget {
  final ShellNavigationNode node;
  final bool active;
  final FutureOr<void> Function(ShellNavigationNode node) onNavigate;

  const _BreadcrumbSegment({required this.node, required this.active, required this.onNavigate});

  @override
  State<_BreadcrumbSegment> createState() => _BreadcrumbSegmentState();
}

class _BreadcrumbSegmentState extends State<_BreadcrumbSegment> {
  final MenuController _menuController = MenuController();
  List<_BreadcrumbMenuNode> _menuNodes = const [];

  Future<List<_BreadcrumbMenuNode>> _loadNodes(ShellNavigationNode node, Set<String> ancestors) async {
    if (ancestors.contains(node.id)) return [];
    final path = {...ancestors, node.id};
    final provided = await node.childrenProvider?.call() ?? const <ShellNavigationNode>[];
    final children = <String, ShellNavigationNode>{
      for (final child in node.children) child.id: child,
      for (final child in provided) child.id: child,
    }.values.where((child) => child.enabled);
    return [for (final child in children) _BreadcrumbMenuNode(child, await _loadNodes(child, path))];
  }

  Future<void> _openMenu() async {
    final nodes = await _loadNodes(widget.node, const {});
    if (!mounted || nodes.isEmpty) return;
    setState(() => _menuNodes = nodes);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _menuController.open();
    });
  }

  Widget _menuItem(_BreadcrumbMenuNode entry) {
    final node = entry.node;
    final label = Row(
      children: [
        if (node.icon case final icon?) ...[Icon(icon, size: 16), const SizedBox(width: 8)],
        Flexible(child: Text(node.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
    if (entry.children.isNotEmpty) {
      return SubmenuButton(menuChildren: [for (final child in entry.children) _menuItem(child)], child: label);
    }
    return MenuItemButton(onPressed: () => unawaited(Future<void>.sync(() => widget.onNavigate(node))), child: label);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMenu = widget.node.childrenProvider != null || widget.node.children.isNotEmpty;
    return MenuAnchor(
      controller: _menuController,
      menuChildren: [for (final node in _menuNodes) _menuItem(node)],
      builder: (context, _, _) => Tooltip(
        message: widget.node.tooltip ?? widget.node.label,
        child: TextButton(
          key: ValueKey('breadcrumb-node-${widget.node.id}'),
          onPressed: !widget.node.enabled
              ? null
              : hasMenu
              ? _openMenu
              : () => unawaited(Future<void>.sync(() => widget.onNavigate(widget.node))),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(0, 24),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            foregroundColor: widget.active ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
          child: MergeSemantics(
            child: Semantics(
              label: widget.node.accessibilityLabel ?? widget.node.label,
              button: true,
              enabled: widget.node.enabled,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.node.icon case final icon?) ...[Icon(icon, size: 14), const SizedBox(width: 2)],
                  Flexible(
                    child: Text(
                      widget.node.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: widget.active ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        fontWeight: widget.active ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BreadcrumbMenuNode {
  final ShellNavigationNode node;
  final List<_BreadcrumbMenuNode> children;

  const _BreadcrumbMenuNode(this.node, this.children);
}

class _BreadcrumbMenuButton extends StatefulWidget {
  final String label;
  final String tooltip;
  final IconData icon;
  final ShellNavigationChildrenProvider loadNodes;
  final FutureOr<void> Function(ShellNavigationNode node) onSelect;

  const _BreadcrumbMenuButton({
    super.key,
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.loadNodes,
    required this.onSelect,
  });

  @override
  State<_BreadcrumbMenuButton> createState() => _BreadcrumbMenuButtonState();
}

class _BreadcrumbMenuButtonState extends State<_BreadcrumbMenuButton> {
  Future<void> _openMenu() async {
    final nodes = (await widget.loadNodes()).where((node) => node.enabled).toList();
    if (!mounted || nodes.isEmpty) return;
    final box = context.findRenderObject()! as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero);
    final screen = MediaQuery.sizeOf(context);
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        topLeft.dx,
        topLeft.dy,
        screen.width - topLeft.dx - box.size.width,
        screen.height - topLeft.dy - box.size.height,
      ),
      items: [
        for (final node in nodes)
          PopupMenuItem(
            value: node.id,
            height: 32,
            child: Semantics(
              label: node.accessibilityLabel ?? node.label,
              child: Row(
                children: [
                  if (node.icon case final icon?) ...[Icon(icon, size: 16), const SizedBox(width: 8)],
                  Flexible(child: Text(node.label, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ),
      ],
    );
    if (selected == null || !mounted) return;
    final node = nodes.where((candidate) => candidate.id == selected).firstOrNull;
    if (node != null) await widget.onSelect(node);
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: widget.tooltip,
    onPressed: () => unawaited(_openMenu()),
    icon: Icon(widget.icon, size: 14),
    style: IconButton.styleFrom(
      minimumSize: const Size(20, 24),
      maximumSize: const Size(20, 24),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    ),
  );
}

class _StatusItemButton extends StatelessWidget {
  final ShellStatusItem item;
  final double width;

  const _StatusItemButton({required this.item, required this.width});

  @override
  Widget build(BuildContext context) {
    final color = switch (item.severity) {
      ShellStatusSeverity.normal => Theme.of(context).colorScheme.onSurfaceVariant,
      ShellStatusSeverity.success => Colors.green,
      ShellStatusSeverity.warning => Colors.orange,
      ShellStatusSeverity.error => Theme.of(context).colorScheme.error,
    };
    return SizedBox(
      width: width,
      height: 24,
      child: Tooltip(
        message: item.tooltip ?? item.label,
        child: Semantics(
          button: item.onTap != null || item.detailsBuilder != null,
          label: item.label,
          child: TextButton(
            onPressed: item.onTap == null && item.detailsBuilder == null ? null : () => _activateStatus(context, item),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size(width, 24),
              maximumSize: Size(width, 24),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              foregroundColor: color,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.progress case final value?) ...[
                  SizedBox(width: 22, child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 2)),
                  const SizedBox(width: 4),
                ],
                if (item.icon case final icon?) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
                Flexible(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _activateStatus(BuildContext context, ShellStatusItem item) {
    if (item.onTap case final action?) {
      action();
    } else if (item.detailsBuilder case final details?) {
      unawaited(
        showDialog<void>(
          context: context,
          builder: (context) => Dialog(child: details(context)),
        ),
      );
    }
  }
}
