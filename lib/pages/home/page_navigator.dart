import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_template/core/settings.dart';

import 'package:flutter_template/l10n/l10n_x.dart';
import 'package:flutter_template/pages/home/widgets/page_navigation_animation.dart';
import 'package:flutter_template/pages/page1/page1_page.dart';
import 'package:flutter_template/pages/page2/page2_page.dart';
import 'package:flutter_template/pages/page3/page3_page.dart';
import 'package:flutter_template/pages/page4/page4_page.dart';
import 'package:flutter_template/pages/page5/page5_page.dart';
import 'package:flutter_template/pages/page6/page6_page.dart';

enum PageItem { page1, page2, page3, page4, page5, page6 }

PageItem? pageItemFromId(String id) {
  for (final item in PageItem.values) {
    if (item.name == id) return item;
  }
  return null;
}

List<PageItem> orderedPageItemsFromSettings(List<String> order) {
  final orderedItems = <PageItem>[];
  final seenItems = <PageItem>{};
  for (final id in order) {
    final item = pageItemFromId(id);
    if (item != null && seenItems.add(item)) orderedItems.add(item);
  }
  for (final item in PageItem.values) {
    if (seenItems.add(item)) orderedItems.add(item);
  }
  return orderedItems;
}

Set<PageItem> hiddenPageItemsFromSettings(List<String> hiddenItems) {
  return hiddenItems.map(pageItemFromId).whereType<PageItem>().where((item) => item != PageItem.page6).toSet();
}

List<String> pageItemIds(Iterable<PageItem> items) => items.map((item) => item.name).toList();

class PageItemPresentation {
  final String title;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final double iconPaddingLeft;
  final double iconPaddingRight;

  const PageItemPresentation({
    required this.title,
    required this.activeIcon,
    required this.inactiveIcon,
    this.iconPaddingLeft = 10,
    this.iconPaddingRight = 10,
  });
}

PageItemPresentation pageItemPresentation(BuildContext context, PageItem item) {
  switch (item) {
    case PageItem.page1:
      return PageItemPresentation(
        title: context.l10n.page1Title,
        activeIcon: Icons.home,
        inactiveIcon: Icons.home_outlined,
        iconPaddingLeft: 0,
      );
    case PageItem.page2:
      return PageItemPresentation(
        title: context.l10n.page2Title,
        activeIcon: Icons.calendar_month,
        inactiveIcon: Icons.calendar_month_outlined,
        iconPaddingLeft: 14,
      );
    case PageItem.page3:
      return PageItemPresentation(
        title: context.l10n.page3Title,
        activeIcon: Icons.map,
        inactiveIcon: Icons.map_outlined,
      );
    case PageItem.page4:
      return PageItemPresentation(
        title: context.l10n.page4Title,
        activeIcon: Icons.restaurant,
        inactiveIcon: Icons.restaurant_outlined,
      );
    case PageItem.page5:
      return PageItemPresentation(
        title: context.l10n.page5Title,
        activeIcon: Icons.account_balance_wallet,
        inactiveIcon: Icons.account_balance_wallet_outlined,
      );
    case PageItem.page6:
      return PageItemPresentation(
        title: context.l10n.page6Title,
        activeIcon: Icons.more_horiz,
        inactiveIcon: Icons.more_horiz,
        iconPaddingLeft: 5,
        iconPaddingRight: 0,
      );
  }
}

enum ShellViewReusePolicy { never, byRegistration, byInstance }

enum ShellTabLifecycle { restored, opened, activated, deactivated, closing, closed }

typedef ShellViewBuilder = Widget Function(BuildContext context, ShellViewContext view);
typedef ShellDestinationBuilder = Widget Function(
  BuildContext context,
  GlobalKey<NavigatorState> mainNavigatorKey,
  GlobalKey<AnimatedEntryState> entryAnimationKey,
  GlobalKey<AnimatedExitState> exitAnimationKey,
);
typedef ShellTabCloseGuard = FutureOr<bool> Function(BuildContext context, ShellTabPreference tab);
typedef ShellViewActionsBuilder = List<ShellViewAction> Function(BuildContext context, ShellViewContext view);
typedef ShellSectionStatusItemsBuilder = List<ShellStatusItem> Function(BuildContext context);
typedef ShellDestinationAction = FutureOr<void> Function(BuildContext context);
typedef ShellCommandAction = FutureOr<void> Function(BuildContext context);
typedef ShellNavigationAction = FutureOr<void> Function();
typedef ShellNavigationChildrenProvider = FutureOr<List<ShellNavigationNode>> Function();

class ShellNavigationNode {
  final String id;
  final String label;
  final IconData? icon;
  final String? parentId;
  final ShellNavigationAction? onActivate;
  final List<ShellNavigationNode> children;
  final ShellNavigationChildrenProvider? childrenProvider;
  final bool enabled;
  final String? tooltip;
  final String? accessibilityLabel;

  const ShellNavigationNode({
    required this.id,
    required this.label,
    this.icon,
    this.parentId,
    this.onActivate,
    this.children = const [],
    this.childrenProvider,
    this.enabled = true,
    this.tooltip,
    this.accessibilityLabel,
  });
}

/// A tab-owned navigation path. Only stable node IDs are persisted by the shell.
class ShellBreadcrumbController extends ChangeNotifier {
  ShellBreadcrumbController({Iterable<String> initialPath = const []}) : _pathIds = List.of(initialPath);

  final Map<String, ShellNavigationNode> _nodes = {};
  List<String> _pathIds;
  int _revision = 0;
  bool _notifyScheduled = false;
  bool _disposed = false;

  List<ShellNavigationNode> get activePath =>
      _pathIds.map((id) => _nodes[id]).whereType<ShellNavigationNode>().toList();
  List<String> get activePathIds => List.unmodifiable(_pathIds);
  bool containsNode(String id) => _nodes.containsKey(id);

  void registerNode(ShellNavigationNode node) => registerNodes([node]);

  void registerNodes(Iterable<ShellNavigationNode> nodes) {
    var changed = false;
    for (final node in nodes) {
      final previous = _nodes[node.id];
      changed = previous == null || !_sameNode(previous, node) || changed;
      _nodes[node.id] = node;
    }
    if (changed) {
      _revision++;
      _notifyChanged();
    }
  }

  void unregisterNode(String id) {
    if (!_nodes.containsKey(id)) return;
    final removed = <String>{id};
    var changed = true;
    while (changed) {
      changed = false;
      for (final node in _nodes.values) {
        if (node.parentId case final parentId? when removed.contains(parentId)) {
          changed = removed.add(node.id) || changed;
        }
      }
    }
    for (final nodeId in removed) {
      _nodes.remove(nodeId);
    }
    final index = _pathIds.indexWhere(removed.contains);
    if (index >= 0) _pathIds = _pathIds.take(index).toList();
    _revision++;
    _notifyChanged();
  }

  void setPath(Iterable<ShellNavigationNode> path) {
    final nodes = path.toList();
    final ids = nodes.map((node) => node.id).toList();
    var changed = !listEquals(ids, _pathIds);
    for (final node in nodes) {
      final previous = _nodes[node.id];
      changed = previous == null || !_sameNode(previous, node) || changed;
      _nodes[node.id] = node;
    }
    if (!changed) return;
    _pathIds = ids;
    _revision++;
    _notifyChanged();
  }

  void restorePath(Iterable<String> ids) {
    final path = List<String>.of(ids);
    if (listEquals(path, _pathIds)) return;
    _pathIds = path;
    _revision++;
    _notifyChanged();
  }

  bool hasChildren(String id) {
    final node = _nodes[id];
    return node != null &&
        (node.children.isNotEmpty ||
            node.childrenProvider != null ||
            _nodes.values.any((child) => child.parentId == id));
  }

  Future<List<ShellNavigationNode>> getChildren(String id) async {
    final node = _nodes[id];
    if (node == null || !node.enabled) return const [];
    final provided = await node.childrenProvider?.call() ?? const [];
    final children = <String, ShellNavigationNode>{
      for (final child in node.children) child.id: _childOf(child, id),
      for (final child in _nodes.values.where((child) => child.parentId == id)) child.id: child,
      for (final child in provided) child.id: _childOf(child, id),
    };
    _nodes.addAll(children);
    return children.values.where((child) => child.enabled).toList();
  }

  Future<void> navigateTo(String nodeId) async {
    final node = _nodes[nodeId];
    if (node == null || !node.enabled) return;
    final path = <ShellNavigationNode>[];
    final visited = <String>{};
    ShellNavigationNode? current = node;
    while (current != null && visited.add(current.id)) {
      path.insert(0, current);
      current = current.parentId == null ? null : _nodes[current.parentId];
    }
    final revision = _revision;
    await node.onActivate?.call();
    if (_revision == revision) setPath(path);
  }

  bool _sameNode(ShellNavigationNode left, ShellNavigationNode right) =>
      left.id == right.id &&
      left.label == right.label &&
      left.icon == right.icon &&
      left.parentId == right.parentId &&
      left.enabled == right.enabled &&
      left.tooltip == right.tooltip &&
      left.accessibilityLabel == right.accessibilityLabel &&
      left.children.map((node) => '${node.id}\u0000${node.label}').join('\u0001') ==
          right.children.map((node) => '${node.id}\u0000${node.label}').join('\u0001');

  ShellNavigationNode _childOf(ShellNavigationNode child, String parentId) => child.parentId == null
      ? ShellNavigationNode(
          id: child.id,
          label: child.label,
          icon: child.icon,
          parentId: parentId,
          onActivate: child.onActivate,
          children: child.children,
          childrenProvider: child.childrenProvider,
          enabled: child.enabled,
          tooltip: child.tooltip,
          accessibilityLabel: child.accessibilityLabel,
        )
      : child;

  void _notifyChanged() {
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      notifyListeners();
      return;
    }
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class ShellViewContext {
  final ShellTabPreference tab;
  final bool isRestored;
  final ValueListenable<ShellTabLifecycle> lifecycle;
  final GlobalKey<NavigatorState> mainNavigatorKey;
  final GlobalKey<AnimatedEntryState> entryAnimationKey;
  final GlobalKey<AnimatedExitState> exitAnimationKey;
  final ShellBreadcrumbController breadcrumbs;

  const ShellViewContext({
    required this.tab,
    required this.isRestored,
    required this.lifecycle,
    required this.mainNavigatorKey,
    required this.entryAnimationKey,
    required this.exitAnimationKey,
    required this.breadcrumbs,
  });

  String get instanceId => tab.instanceId ?? tab.id;
  Map<String, dynamic> get parameters => tab.parameters;
}

class ShellViewAction {
  final String id;
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const ShellViewAction({required this.id, required this.label, required this.onPressed, this.icon});
}

enum ShellStatusSeverity { normal, success, warning, error }

class ShellStatusItem {
  final String id;
  final String label;
  final IconData? icon;
  final int priority;
  final ShellStatusSeverity severity;
  final String? tooltip;
  final VoidCallback? onTap;
  final bool Function()? isVisible;
  final double? progress;
  final WidgetBuilder? detailsBuilder;

  const ShellStatusItem({
    required this.id,
    required this.label,
    this.icon,
    this.priority = 0,
    this.severity = ShellStatusSeverity.normal,
    this.tooltip,
    this.onTap,
    this.isVisible,
    this.progress,
    this.detailsBuilder,
  });
}

abstract class ShellStatusProvider extends ChangeNotifier {
  List<ShellStatusItem> get items;
}

typedef ShellStatusProviderFactory = ShellStatusProvider Function(String instanceId);

class ShellDestination {
  final String id;
  final String Function(BuildContext) title;
  final IconData icon;
  final IconData? inactiveIcon;
  final bool lockedVisible;
  final String? defaultViewId;
  final Set<String>? allowedViewIds;
  @Deprecated('Move view content to ShellViewRegistration.')
  final ShellDestinationBuilder? builder;
  final String? openViewId;
  final String? commandId;
  final WidgetBuilder? panelBuilder;
  final WidgetBuilder? inspectorBuilder;
  final ShellSectionStatusItemsBuilder? statusItemsBuilder;
  final ShellStatusProvider? statusProvider;
  final ShellDestinationAction? onSelected;

  const ShellDestination({
    required this.id,
    required this.title,
    required this.icon,
    this.inactiveIcon,
    this.lockedVisible = false,
    this.defaultViewId,
    this.allowedViewIds,
    @Deprecated('Move view content to ShellViewRegistration.') this.builder,
    this.openViewId,
    this.commandId,
    this.panelBuilder,
    this.inspectorBuilder,
    this.statusItemsBuilder,
    this.statusProvider,
    this.onSelected,
  });
}

class ShellViewRegistration {
  final String id;
  final String Function(BuildContext, String instanceId) title;
  @Deprecated('Use viewBuilder for tab-aware view content.')
  final WidgetBuilder? builder;
  final ShellViewBuilder? viewBuilder;
  final String? destinationId;
  final String? contextId;
  final String? moduleId;
  final IconData? icon;
  final String? routePath;
  final ShellViewReusePolicy reusePolicy;
  @Deprecated('Views are independent of destinations.')
  final bool isRoot;
  final bool closeable;
  final ShellTabCloseGuard? onCloseRequested;
  final ShellViewActionsBuilder? toolbarActionsBuilder;
  final ShellViewBuilder? inspectorBuilder;
  final ShellViewBuilder? splitPaneBuilder;
  final ShellStatusProviderFactory? statusProviderFactory;

  const ShellViewRegistration({
    required this.id,
    required this.title,
    @Deprecated('Use viewBuilder for tab-aware view content.') this.builder,
    this.viewBuilder,
    this.destinationId,
    this.contextId,
    this.moduleId,
    this.icon,
    this.routePath,
    this.reusePolicy = ShellViewReusePolicy.never,
    @Deprecated('Views are independent of destinations.') this.isRoot = false,
    this.closeable = true,
    this.onCloseRequested,
    this.toolbarActionsBuilder,
    this.inspectorBuilder,
    this.splitPaneBuilder,
    this.statusProviderFactory,
  });

  bool get hasBuilder => builder != null || viewBuilder != null;

  Widget buildContent(BuildContext context, ShellViewContext view) =>
      viewBuilder?.call(context, view) ?? builder?.call(context) ?? const SizedBox.shrink();
}

class ShellModule {
  final String id;
  final String Function(BuildContext) title;
  final WidgetBuilder builder;

  const ShellModule({required this.id, required this.title, required this.builder});
}

class ShellCommandRegistration {
  final String id;
  final String Function(BuildContext) title;
  final ShellCommandAction run;

  const ShellCommandRegistration({required this.id, required this.title, required this.run});
}

class ShellContext {
  final String id;
  final String Function(BuildContext) title;
  final List<ShellModule> modules;

  const ShellContext({required this.id, required this.title, required this.modules});
}

class ShellConfig {
  final String Function(BuildContext) title;
  final List<ShellDestination> destinations;
  final List<ShellViewRegistration> views;
  final List<ShellModule> modules;
  final List<ShellContext> contexts;
  final List<ShellCommandRegistration> commands;
  final List<ShellStatusProvider> globalStatusProviders;
  final WidgetBuilder? inspectorBuilder;
  final WidgetBuilder? splitPaneBuilder;

  const ShellConfig({
    required this.title,
    required this.destinations,
    this.views = const [],
    this.modules = const [],
    this.contexts = const [],
    this.commands = const [],
    this.globalStatusProviders = const [],
    this.inspectorBuilder,
    this.splitPaneBuilder,
  });
}

enum ShellSlotState { content, empty, loading, error, unavailable }

class ShellContentSlot extends StatelessWidget {
  final ShellSlotState state;
  final Widget? child;
  final String? message;
  final VoidCallback? onRetry;

  const ShellContentSlot({super.key, required this.state, this.child, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (state == ShellSlotState.content && child != null) return child!;
    final text = switch (state) {
      ShellSlotState.content || ShellSlotState.empty => message ?? context.l10n.shellPlaceholderBody,
      ShellSlotState.loading => message ?? context.l10n.loading,
      ShellSlotState.error => message ?? context.l10n.generalFailureMessage,
      ShellSlotState.unavailable => message ?? context.l10n.shellMissingView,
    };
    return Semantics(
      liveRegion: state == ShellSlotState.error,
      child: Center(
        child: state == ShellSlotState.loading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (message != null) ...[const SizedBox(height: 12), Text(text, textAlign: TextAlign.center)],
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(text, textAlign: TextAlign.center),
                  if (state == ShellSlotState.error && onRetry != null) ...[
                    const SizedBox(height: 12),
                    TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
                  ],
                ],
              ),
      ),
    );
  }
}

ShellConfig defaultShellConfig() => ShellConfig(
  title: (context) => context.l10n.appTitle,
  destinations: PageItem.values.map((item) {
    final presentation = _pageItemIcons(item);
    return ShellDestination(
      id: item.name,
      title: (context) => pageItemPresentation(context, item).title,
      icon: presentation.activeIcon,
      inactiveIcon: presentation.inactiveIcon,
      lockedVisible: item == PageItem.page6,
      defaultViewId: item.name,
      allowedViewIds: item == PageItem.page6 ? {'page6', 'settings'} : {item.name},
    );
  }).toList(),
  views: defaultShellViews(),
);

List<ShellViewRegistration> defaultShellViews() => PageItem.values.map((item) {
  final presentation = _pageItemIcons(item);
  return ShellViewRegistration(
    id: item.name,
    title: (context, instanceId) {
      final title = pageItemPresentation(context, item).title;
      final instanceNumber = int.tryParse(instanceId.split('-').last);
      return instanceNumber == null || instanceNumber == 1 ? title : '$title $instanceNumber';
    },
    destinationId: item.name,
    icon: presentation.activeIcon,
    routePath: '/${item.name}',
    viewBuilder: (context, view) => _buildPageItem(context, view, item),
  );
}).toList();

Widget _buildPageItem(BuildContext context, ShellViewContext view, PageItem item) {
  return switch (item) {
    PageItem.page1 => Page1Page(
      mainNavigatorKey: view.mainNavigatorKey,
      pageEntryAnimationKey: view.entryAnimationKey,
      pageExitAnimationKey: view.exitAnimationKey,
    ),
    PageItem.page2 => Page2Page(
      mainNavigatorKey: view.mainNavigatorKey,
      pageEntryAnimationKey: view.entryAnimationKey,
      pageExitAnimationKey: view.exitAnimationKey,
    ),
    PageItem.page3 => Page3Page(
      pageEntryAnimationKey: view.entryAnimationKey,
      pageExitAnimationKey: view.exitAnimationKey,
    ),
    PageItem.page4 => Page4Page(
      mainNavigatorKey: view.mainNavigatorKey,
      pageEntryAnimationKey: view.entryAnimationKey,
      pageExitAnimationKey: view.exitAnimationKey,
    ),
    PageItem.page5 => Page5Page(
      pageEntryAnimationKey: view.entryAnimationKey,
      pageExitAnimationKey: view.exitAnimationKey,
    ),
    PageItem.page6 => Page6Page(
      mainNavigatorKey: view.mainNavigatorKey,
      pageEntryAnimationKey: view.entryAnimationKey,
      pageExitAnimationKey: view.exitAnimationKey,
    ),
  };
}

PageItemPresentation _pageItemIcons(PageItem item) {
  switch (item) {
    case PageItem.page1:
      return const PageItemPresentation(title: '', activeIcon: Icons.home, inactiveIcon: Icons.home_outlined);
    case PageItem.page2:
      return const PageItemPresentation(
        title: '',
        activeIcon: Icons.calendar_month,
        inactiveIcon: Icons.calendar_month_outlined,
      );
    case PageItem.page3:
      return const PageItemPresentation(title: '', activeIcon: Icons.map, inactiveIcon: Icons.map_outlined);
    case PageItem.page4:
      return const PageItemPresentation(
        title: '',
        activeIcon: Icons.restaurant,
        inactiveIcon: Icons.restaurant_outlined,
      );
    case PageItem.page5:
      return const PageItemPresentation(
        title: '',
        activeIcon: Icons.account_balance_wallet,
        inactiveIcon: Icons.account_balance_wallet_outlined,
      );
    case PageItem.page6:
      return const PageItemPresentation(title: '', activeIcon: Icons.more_horiz, inactiveIcon: Icons.more_horiz);
  }
}

class PageNavigatorRoutes {
  static const String root = '/';
  static const String detail = '/detail';
}
