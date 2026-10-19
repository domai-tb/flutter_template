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
  return hiddenItems.map(pageItemFromId).whereType<PageItem>().toSet();
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

typedef ShellOpenView = Future<String?> Function(
  String registrationId, {
  String? sectionId,
  String? instanceId,
  Map<String, dynamic> parameters,
  String? title,
});
typedef ShellCloseTab = Future<bool> Function(String tabId);
typedef ShellActivateTab = Future<bool> Function(String sectionId, String tabId);
typedef ShellSelectSection = Future<bool> Function(String sectionId);
typedef ShellWorkspaceLayoutChanged = void Function({
  required bool isOpen,
  required List<double> weights,
  required bool persist,
});

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
  final ShellNavigationController navigation;
  final ShellInspectorController inspector;
  final ShellStatusController status;
  final ShellToolbarController toolbar;
  final ShellWorkspaceController workspace;

  const ShellViewContext({
    required this.tab,
    required this.isRestored,
    required this.lifecycle,
    required this.mainNavigatorKey,
    required this.entryAnimationKey,
    required this.exitAnimationKey,
    required this.breadcrumbs,
    required this.navigation,
    required this.inspector,
    required this.status,
    required this.toolbar,
    required this.workspace,
  });

  String get instanceId => tab.instanceId ?? tab.id;
  Map<String, dynamic> get parameters => tab.parameters;
}

/// Provides navigation commands scoped to the owning tab and section.
///
/// Cross-section commands use the shell's normal section-selection path, so
/// default views, active-tab restoration and section callbacks remain intact.
class ShellNavigationController {
  final String sectionId;
  final String tabId;
  late final ShellOpenView _openView;
  late final ShellCloseTab _closeTab;
  late final ShellActivateTab _activateTab;
  late final ShellSelectSection _selectSection;
  bool _disposed = false;

  /// Creates a tab-scoped navigation controller.
  ShellNavigationController({
    required this.sectionId,
    required this.tabId,
    required ShellOpenView openView,
    required ShellCloseTab closeTab,
    required ShellActivateTab activateTab,
    required ShellSelectSection selectSection,
  }) {
    _openView = openView;
    _closeTab = closeTab;
    _activateTab = activateTab;
    _selectSection = selectSection;
  }

  /// Opens a registered view in this section or an explicitly named section.
  Future<String?> openView(
    String registrationId, {
    String? sectionId,
    String? instanceId,
    Map<String, dynamic> parameters = const {},
    String? title,
  }) => _disposed
      ? Future<String?>.value()
      : _openView(
          registrationId,
          sectionId: sectionId ?? this.sectionId,
          instanceId: instanceId,
          parameters: parameters,
          // Forward a caller-provided title even when it is null.
          // ignore: avoid_redundant_argument_values
          title: title,
        );

  /// Activates a tab in this section or an explicitly named section.
  Future<bool> activateTab(String tabId, {String? sectionId}) =>
      _disposed ? Future.value(false) : _activateTab(sectionId ?? this.sectionId, tabId);

  /// Closes this tab or a tab in the same application shell.
  Future<bool> closeTab({String? tabId}) => _disposed ? Future.value(false) : _closeTab(tabId ?? this.tabId);

  /// Selects a section through the shell's complete navigation flow.
  Future<bool> selectSection(String sectionId) => _disposed ? Future.value(false) : _selectSection(sectionId);

  /// Invalidates commands when the owning tab is closed.
  void dispose() => _disposed = true;
}

/// A page-provided section displayed in the shell Inspector.
class ShellInspectorSection {
  final String id;
  final String title;
  final WidgetBuilder builder;
  final bool initiallyExpanded;

  /// Creates an Inspector section with stable identity and page-built content.
  const ShellInspectorSection({
    required this.id,
    required this.title,
    required this.builder,
    this.initiallyExpanded = true,
  });
}

/// Holds tab-specific Inspector visibility and content.
///
/// A `null` visibility override inherits the section or application setting.
class ShellInspectorController extends ChangeNotifier {
  ShellInspectorController({bool? isVisible, ValueChanged<bool?>? onVisibilityChanged}) {
    _isVisible = isVisible;
    _onVisibilityChanged = onVisibilityChanged;
  }

  late bool? _isVisible;
  String? _selectionLabel;
  String? _focusedSectionId;
  List<ShellInspectorSection> _sections = const [];
  late final ValueChanged<bool?>? _onVisibilityChanged;

  /// Whether this tab overrides inherited Inspector visibility.
  bool? get isVisible => _isVisible;

  /// The current Inspector section list.
  List<ShellInspectorSection> get sections => List.unmodifiable(_sections);

  /// The label of the page's current Inspector selection.
  String? get selectionLabel => _selectionLabel;

  /// The section most recently requested for focus.
  String? get focusedSectionId => _focusedSectionId;

  /// Opens the Inspector for this tab.
  void open() => setVisible(isVisible: true);

  /// Closes the Inspector for this tab.
  void close() => setVisible(isVisible: false);

  /// Sets tab visibility, or clears the override when [isVisible] is `null`.
  void setVisible({required bool? isVisible}) {
    if (_isVisible == isVisible) return;
    _isVisible = isVisible;
    _onVisibilityChanged?.call(isVisible);
    notifyListeners();
  }

  /// Restores a saved visibility override without writing it back to settings.
  void restoreVisibility({required bool? isVisible}) {
    if (_isVisible == isVisible) return;
    _isVisible = isVisible;
    notifyListeners();
  }

  /// Replaces the Inspector sections and removes duplicate section IDs.
  void setSections(Iterable<ShellInspectorSection> sections) {
    final next = <String, ShellInspectorSection>{};
    for (final section in sections) {
      if (section.id.trim().isEmpty) throw ArgumentError.value(section.id, 'sections.id');
      if (next.containsKey(section.id)) throw ArgumentError.value(section.id, 'sections', 'duplicate section ID');
      next[section.id] = section;
    }
    if (mapEquals(next, {for (final section in _sections) section.id: section})) return;
    _sections = next.values.toList(growable: false);
    if (_focusedSectionId != null && !next.containsKey(_focusedSectionId)) _focusedSectionId = null;
    notifyListeners();
  }

  /// Updates the current selection label shown above Inspector sections.
  void setSelection(String? label) {
    if (_selectionLabel == label) return;
    _selectionLabel = label;
    notifyListeners();
  }

  /// Requests focus and scrolling for a registered Inspector section.
  void focusSection(String id) {
    if (!_sections.any((section) => section.id == id)) return;
    _focusedSectionId = id;
    if (_isVisible != true) {
      open();
    } else {
      notifyListeners();
    }
  }
}

/// Publishes contextual status items for the active tab.
class ShellStatusController extends ChangeNotifier {
  List<ShellStatusItem> _items = const [];

  /// The current tab-owned status items.
  List<ShellStatusItem> get items => List.unmodifiable(_items);

  /// Replaces all status items after validating their stable IDs.
  void setItems(Iterable<ShellStatusItem> items) {
    final next = items.toList(growable: false);
    final ids = <String>{};
    for (final item in next) {
      if (item.id.trim().isEmpty || !ids.add(item.id)) {
        throw ArgumentError.value(item.id, 'items', 'status IDs must be non-empty and unique');
      }
    }
    _items = next;
    notifyListeners();
  }

  /// Adds or replaces a status item by ID.
  void setItem(ShellStatusItem item) {
    _items = [..._items.where((existing) => existing.id != item.id), item];
    notifyListeners();
  }

  /// Removes the status item with [id].
  void removeItem(String id) {
    final next = _items.where((item) => item.id != id).toList(growable: false);
    if (next.length == _items.length) return;
    _items = next;
    notifyListeners();
  }
}

/// Publishes contextual toolbar actions for the active tab.
class ShellToolbarController extends ChangeNotifier {
  List<ShellViewAction> _actions = const [];

  /// The current tab-owned toolbar actions.
  List<ShellViewAction> get actions => List.unmodifiable(_actions);

  /// Replaces toolbar actions after validating their stable IDs.
  void setActions(Iterable<ShellViewAction> actions) {
    final next = actions.toList(growable: false);
    final ids = <String>{};
    for (final action in next) {
      if (action.id.trim().isEmpty || !ids.add(action.id)) {
        throw ArgumentError.value(action.id, 'actions', 'action IDs must be non-empty and unique');
      }
    }
    _actions = next;
    notifyListeners();
  }
}

/// Describes an additional pane that a tab asks the shell to host.
class ShellWorkspacePane {
  final String id;
  final String title;
  final ShellViewBuilder builder;
  final double minWidth;

  /// Creates a secondary workspace pane.
  const ShellWorkspacePane({required this.id, required this.title, required this.builder, this.minWidth = 240});
}

/// Owns split-pane requests and per-tab split layout preferences.
class ShellWorkspaceController extends ChangeNotifier {
  ShellWorkspaceController({
    required bool initialSplitOpen,
    bool hasSplitPreference = false,
    List<double> initialWeights = const [],
    ShellWorkspaceLayoutChanged? onLayoutChanged,
  }) : _isSplitOpen = initialSplitOpen,
       _weights = List.of(initialWeights) {
    _hasSplitPreference = hasSplitPreference;
    _onLayoutChanged = onLayoutChanged;
  }

  bool _isSplitOpen;
  late bool _hasSplitPreference;
  List<double> _weights;
  List<ShellWorkspacePane> _panes = const [];
  String? _collapsedPaneId;
  late final ShellWorkspaceLayoutChanged? _onLayoutChanged;

  /// Whether additional panes are currently shown.
  bool get isSplitOpen => _isSplitOpen;

  /// The current secondary pane registrations.
  List<ShellWorkspacePane> get panes => List.unmodifiable(_panes);

  /// Normalized width weights, including the primary pane.
  List<double> get weights => List.unmodifiable(_weights);

  /// The pane selected while the split is collapsed for a narrow window.
  String? get collapsedPaneId => _collapsedPaneId;

  /// Requests up to two secondary panes, producing a one-, two- or three-column workspace.
  void requestPanes(Iterable<ShellWorkspacePane> panes, {List<double>? weights}) {
    final next = panes.toList(growable: false);
    final ids = <String>{};
    if (next.length > 2) throw ArgumentError.value(next.length, 'panes', 'at most two secondary panes are supported');
    for (final pane in next) {
      if (pane.id.trim().isEmpty || !ids.add(pane.id) || !pane.minWidth.isFinite || pane.minWidth < 120) {
        throw ArgumentError.value(pane.id, 'panes', 'pane IDs must be unique and minimum widths at least 120dp');
      }
    }
    final samePanes =
        _panes.length == next.length &&
        List.generate(_panes.length, (index) {
          final previous = _panes[index];
          final pane = next[index];
          return previous.id == pane.id &&
              previous.title == pane.title &&
              previous.minWidth == pane.minWidth &&
              identical(previous.builder, pane.builder);
        }).every((same) => same);
    _panes = next;
    if (samePanes && weights == null) return;
    if (weights != null) {
      _weights = _normalizeWeights(weights, next.length + 1);
    } else if (_weights.length != next.length + 1) {
      _weights = _normalizeWeights(_weights, next.length + 1);
    }
    if (next.isNotEmpty && !_hasSplitPreference) {
      _isSplitOpen = true;
      _hasSplitPreference = true;
      _onLayoutChanged?.call(isOpen: _isSplitOpen, weights: List.unmodifiable(_weights), persist: true);
    }
    if (next.isEmpty) _isSplitOpen = false;
    if (_collapsedPaneId != 'primary' && !ids.contains(_collapsedPaneId)) _collapsedPaneId = null;
    notifyListeners();
  }

  /// Opens the requested split panes.
  void openSplit() => setSplitOpen(isOpen: true);

  /// Closes secondary panes without discarding their registrations or state.
  void closeSplit() => setSplitOpen(isOpen: false);

  /// Sets per-tab split visibility and persists the preference.
  void setSplitOpen({required bool isOpen}) {
    if (_isSplitOpen == isOpen && _hasSplitPreference) return;
    _isSplitOpen = isOpen;
    _hasSplitPreference = true;
    _notifyLayout(persist: true);
  }

  /// Updates pane widths; callers can persist once a drag gesture ends.
  void setWeights(List<double> weights, {bool persist = false}) {
    final next = _normalizeWeights(weights, _panes.length + 1);
    if (listEquals(next, _weights)) {
      if (persist) _notifyLayout(persist: true);
      return;
    }
    _weights = next;
    _notifyLayout(persist: persist);
  }

  /// Restores saved split preferences without persisting them again.
  void restoreLayout({required bool isOpen, required bool hasPreference, required List<double> weights}) {
    final nextWeights = weights.length <= 3 && weights.every((weight) => weight.isFinite && weight > 0)
        ? List<double>.of(weights)
        : const <double>[];
    if (_isSplitOpen == isOpen && _hasSplitPreference == hasPreference && listEquals(_weights, nextWeights)) return;
    _isSplitOpen = isOpen;
    _hasSplitPreference = hasPreference;
    _weights = nextWeights;
    notifyListeners();
  }

  /// Selects a pane while the layout is collapsed to one visible column.
  void selectCollapsedPane(String paneId) {
    if (paneId != 'primary' && !_panes.any((pane) => pane.id == paneId)) return;
    if (_collapsedPaneId == paneId) return;
    _collapsedPaneId = paneId;
    notifyListeners();
  }

  List<double> _normalizeWeights(List<double> weights, int count) {
    final valid = weights.length == count && weights.every((weight) => weight.isFinite && weight > 0)
        ? weights
        : List<double>.filled(count, 1);
    final total = valid.fold<double>(0, (sum, weight) => sum + weight);
    return valid.map((weight) => weight / total).toList(growable: false);
  }

  void _notifyLayout({required bool persist}) {
    _onLayoutChanged?.call(isOpen: _isSplitOpen, weights: List.unmodifiable(_weights), persist: persist);
    notifyListeners();
  }
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
  final bool isUtility;
  final bool showOnMobile;
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
    this.isUtility = false,
    this.showOnMobile = true,
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

  /// Returns this configuration with selected registration collections replaced.
  ShellConfig copyWith({
    List<ShellDestination>? destinations,
    List<ShellViewRegistration>? views,
    List<ShellModule>? modules,
    List<ShellContext>? contexts,
    List<ShellCommandRegistration>? commands,
    List<ShellStatusProvider>? globalStatusProviders,
    WidgetBuilder? inspectorBuilder,
    WidgetBuilder? splitPaneBuilder,
  }) => ShellConfig(
    title: title,
    destinations: destinations ?? this.destinations,
    views: views ?? this.views,
    modules: modules ?? this.modules,
    contexts: contexts ?? this.contexts,
    commands: commands ?? this.commands,
    globalStatusProviders: globalStatusProviders ?? this.globalStatusProviders,
    inspectorBuilder: inspectorBuilder ?? this.inspectorBuilder,
    splitPaneBuilder: splitPaneBuilder ?? this.splitPaneBuilder,
  );
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
  destinations: [
    ...PageItem.values.map((item) {
      final presentation = _pageItemIcons(item);
      return ShellDestination(
        id: item.name,
        title: (context) => pageItemPresentation(context, item).title,
        icon: presentation.activeIcon,
        inactiveIcon: presentation.inactiveIcon,
        defaultViewId: item.name,
        allowedViewIds: switch (item) {
          PageItem.page1 => const {'page1', 'demo.workspace', 'demo.report'},
          PageItem.page2 => const {'page2', 'demo.session'},
          _ => {item.name},
        },
      );
    }),
    ShellDestination(
      id: 'profile',
      title: (context) => context.l10n.profile,
      icon: Icons.person_outline,
      inactiveIcon: Icons.person_outline,
      lockedVisible: true,
      isUtility: true,
      showOnMobile: false,
      defaultViewId: 'profile',
      allowedViewIds: const {'profile'},
    ),
    ShellDestination(
      id: 'settings',
      title: (context) => context.l10n.settingsTitle,
      icon: Icons.settings_outlined,
      inactiveIcon: Icons.settings_outlined,
      lockedVisible: true,
      isUtility: true,
      defaultViewId: 'settings',
      allowedViewIds: const {'settings'},
    ),
  ],
  views: defaultShellViews(),
);

List<ShellViewRegistration> defaultShellViews() =>
    PageItem.values.map((item) {
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
    }).toList()..addAll([
      ShellViewRegistration(
        id: 'demo.workspace',
        title: (_, _) => 'Workspace',
        destinationId: 'page1',
        viewBuilder: (_, view) => ShellDemoView(view: view, splitPaneCount: 1),
      ),
      ShellViewRegistration(
        id: 'demo.report',
        title: (_, _) => 'Report',
        destinationId: 'page1',
        viewBuilder: (_, view) => ShellDemoView(view: view, splitPaneCount: 2),
      ),
      ShellViewRegistration(
        id: 'demo.session',
        title: (_, instanceId) => 'Session $instanceId',
        destinationId: 'page2',
        viewBuilder: (_, view) => ShellDemoView(view: view),
      ),
    ]);

/// Demonstrates tab-scoped shell contributions with independent local state.
class ShellDemoView extends StatefulWidget {
  final ShellViewContext view;
  final int splitPaneCount;

  /// Creates an example registered view for template workspaces.
  const ShellDemoView({super.key, required this.view, this.splitPaneCount = 0});

  @override
  State<ShellDemoView> createState() => _ShellDemoViewState();
}

class _ShellDemoViewState extends State<ShellDemoView> {
  int _count = 0;
  String _selectedNode = 'summary';

  String get _rootId => 'demo-root:${widget.view.instanceId}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publishShellState();
    });
  }

  void _publishShellState() {
    final view = widget.view;
    final children = [
      for (final (id, label) in [('summary', 'Summary'), ('activity', 'Activity')])
        ShellNavigationNode(
          id: 'demo:$id:${view.instanceId}',
          label: label,
          parentId: _rootId,
          onActivate: () {
            setState(() => _selectedNode = id);
            _publishShellState();
          },
        ),
    ];
    view.breadcrumbs.setPath([
      ShellNavigationNode(
        id: _rootId,
        label: 'Overview',
        onActivate: () {
          setState(() => _selectedNode = 'summary');
          _publishShellState();
        },
        children: children,
      ),
      children.firstWhere((node) => node.id == 'demo:$_selectedNode:${view.instanceId}'),
    ]);
    view.status.setItem(
      ShellStatusItem(
        id: 'demo-count',
        label: 'Items: $_count',
        icon: Icons.list_alt,
        severity: ShellStatusSeverity.success,
      ),
    );
    view.inspector
      ..setSelection('Item $_count')
      ..setSections([
        ShellInspectorSection(
          id: 'demo-details',
          title: 'Selection',
          builder: (_) => Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Tab ${view.instanceId} · $_selectedNode · $_count items'),
          ),
        ),
      ])
      ..open();
    view.toolbar.setActions([
      ShellViewAction(id: 'add-item', label: 'Add item', icon: Icons.add, onPressed: _increment),
    ]);
    if (view.tab.registrationId == 'demo.report') {
      view.workspace.requestPanes([
        for (var index = 0; index < widget.splitPaneCount; index++)
          ShellWorkspacePane(
            id: 'demo-pane-$index',
            title: 'Panel ${index + 1}',
            builder: (_, _) => Center(child: Text('Panel ${index + 1} · ${view.instanceId}')),
          ),
      ]);
    }
  }

  void _increment() {
    setState(() => _count++);
    _publishShellState();
  }

  Future<void> _openAnother() async {
    final registrationId = widget.view.tab.registrationId == 'demo.session' ? 'demo.session' : 'demo.report';
    await widget.view.navigation.openView(registrationId);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.view.tab.registrationId, style: Theme.of(context).textTheme.titleLarge),
        Text('Instance: ${widget.view.instanceId}'),
        Text('Selected: $_selectedNode · Local count: $_count'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            FilledButton(onPressed: _increment, child: const Text('Add item')),
            OutlinedButton(onPressed: _openAnother, child: const Text('Open another view')),
            OutlinedButton(onPressed: widget.view.inspector.open, child: const Text('Open Inspector')),
          ],
        ),
      ],
    ),
  );
}

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
