import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, listEquals, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'package:flutter_template/core/app_scope.dart';
import 'package:flutter_template/pages/settings/settings_entity.dart';
import 'package:flutter_template/core/themes.dart';
import 'package:flutter_template/l10n/l10n_x.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';
import 'package:flutter_template/pages/home/default_shell_config.dart';
import 'package:flutter_template/pages/home/shell_navigation_coordinator.dart';
import 'package:flutter_template/pages/home/widgets/bottom_nav_bar.dart';
import 'package:flutter_template/pages/home/widgets/page_navigation_animation.dart';
import 'package:flutter_template/pages/home/widgets/shell_notification_center.dart';
import 'package:flutter_template/pages/home/widgets/shell_status_bar.dart';
import 'package:flutter_template/pages/home/widgets/shell_inspector_sections.dart';
import 'package:flutter_template/pages/home/widgets/shell_split_view.dart';
import 'package:flutter_template/pages/home/widgets/shell_desktop_tab.dart';
import 'package:flutter_template/pages/home/widgets/shell_dialogs.dart';
import 'package:flutter_template/pages/home/widgets/side_nav_bar.dart';
import 'package:flutter_template/pages/profile/login_page.dart';
import 'package:flutter_template/pages/profile/profile_page.dart';
import 'package:flutter_template/pages/settings/settings_controller.dart';

class HomePage extends StatefulWidget {
  final GlobalKey<NavigatorState> mainNavigatorKey;
  final ShellConfig? config;
  final RouteInformation? routeInformation;

  const HomePage({super.key, required this.mainNavigatorKey, this.config, this.routeInformation});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final PageController pageController = PageController();
  final ScrollController _tabScrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<String, GlobalKey<NavigatorState>> navigatorKeys = {};
  final Map<String, GlobalKey<AnimatedExitState>> exitAnimationKeys = {};
  final Map<String, GlobalKey<AnimatedEntryState>> entryAnimationKeys = {};
  final Map<String, GlobalKey> _tabKeys = {};
  final Map<String, ShellStatusProvider> _statusProviders = {};
  final Set<ShellStatusProvider> _sharedStatusProviders = {};
  final Map<String, _ShellTabRuntime> _tabRuntimes = {};

  late final ShellConfig _config;
  late final ShellNavigationCoordinator _navigation;
  late SettingsController _settingsController;
  double _splitRatio = 0.5;
  double pagePosition = 0;
  bool swipeDisabled = false;
  bool _settingsWired = false;
  bool _handlingPlatformRoute = false;
  bool _restoringSettings = false;
  bool _activityPanelOpen = true;
  bool _rightSidebarDrawerOpen = false;
  bool _statusRefreshScheduled = false;
  String? _returnSectionId;
  String? _lastPushedRouteId;
  String? _lastLifecycleActiveId;

  bool get _isPhoneLayout =>
      defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  List<ShellTabPreference> get _tabs => _navigation.tabs;
  List<ShellTabPreference> get _allTabs => _navigation.allTabs;
  String? get _selectedTabId => _navigation.activeId;
  ShellTabPreference? get _activeTab => _navigation.activeTab;
  String get selectedActivityId {
    final activeSection = _navigation.selectedSectionId;
    if (_destinations.any((destination) => destination.id == activeSection)) return activeSection!;
    final selected = _settingsController.settings.selectedActivityId;
    return _destinations.any((destination) => destination.id == selected)
        ? selected!
        : _destinations.firstOrNull?.id ?? '';
  }

  String get currentDestinationId => selectedActivityId;
  String? get _selectedContextId => _settingsController.settings.selectedContextId;
  PageItem get currentPage => pageItemFromId(currentDestinationId) ?? PageItem.page1;

  List<ShellDestination> get _destinations {
    final sections = _navigation.sections;
    final byId = {for (final destination in sections) destination.id: destination};
    final ordered = <ShellDestination>[];
    for (final id in _settingsController.settings.navBarItemOrder) {
      final destination = byId[id];
      if (destination != null && !destination.isUtility && !ordered.contains(destination)) ordered.add(destination);
    }
    for (final destination in sections) {
      if (!destination.isUtility && !ordered.contains(destination)) ordered.add(destination);
    }
    final hidden = _settingsController.settings.hiddenNavBarItems.toSet();
    ordered.removeWhere((destination) => !destination.lockedVisible && hidden.contains(destination.id));
    return [...ordered, ...sections.where((destination) => destination.isUtility)];
  }

  ShellContext? get _selectedContext =>
      _config.contexts.where((context) => context.id == _selectedContextId).firstOrNull;

  List<ShellModule> get _modules => _selectedContext?.modules ?? _config.modules;
  ShellStatusProvider? get _activeStatusProvider => _activeTab == null ? null : _statusProviders[_activeTab!.id];
  ShellDestination? get _activeSection => _navigation.sectionFor(selectedActivityId);
  bool get _hasSplitContent =>
      (_activeTab != null && _tabRuntimes[_activeTab!.id]?.workspace.panes.isNotEmpty == true) ||
      _activeSplitBuilder != null;
  ShellViewBuilder? get _activeSplitBuilder {
    final builder = _activeTab == null ? null : _viewFor(_activeTab!.registrationId)?.splitPaneBuilder;
    if (builder != null) return builder;
    final globalBuilder = _config.splitPaneBuilder;
    return globalBuilder == null ? null : (context, _) => globalBuilder(context);
  }

  bool get _rightSidebarOpen =>
      (_activeTab == null ? null : _tabRuntimes[_activeTab!.id]?.rightSidebar.isVisible) ??
      _activeTab?.inspectorOpen ??
      _navigation.activeWorkspace.inspectorOpen ??
      _settingsController.settings.inspectorOpen;
  bool get _splitOpen =>
      (_activeTab == null ? null : _tabRuntimes[_activeTab!.id]?.workspace.isSplitOpen) ??
      _activeTab?.splitOpen ??
      _settingsController.settings.splitOpen;

  List<ShellWorkspacePreference> _workspacePreferences(Settings settings) {
    final stored = settings.shellWorkspaces.isNotEmpty
        ? settings.shellWorkspaces
        : _legacyWorkspacePreferences(settings);
    final settingsTabs = <ShellTabPreference>[];
    final workspaces = <String, ShellWorkspacePreference>{};
    for (final workspace in stored) {
      final tabs = <ShellTabPreference>[];
      for (final tab in workspace.tabs) {
        if (tab.registrationId == 'settings') {
          settingsTabs.add(tab.copyWith(sectionId: 'settings', destinationId: 'settings'));
        } else {
          tabs.add(tab);
        }
      }
      workspaces[workspace.sectionId] = ShellWorkspacePreference(
        sectionId: workspace.sectionId,
        tabs: tabs,
        activeTabId: tabs.any((tab) => tab.id == workspace.activeTabId) ? workspace.activeTabId : tabs.firstOrNull?.id,
        inspectorOpen: workspace.inspectorOpen,
      );
    }
    if (settingsTabs.isNotEmpty) {
      final activeTabId =
          settingsTabs.where((tab) => tab.id == settings.selectedShellTabId).firstOrNull?.id ?? settingsTabs.first.id;
      workspaces['settings'] = ShellWorkspacePreference(
        sectionId: 'settings',
        tabs: settingsTabs,
        activeTabId: activeTabId,
      );
    }
    return workspaces.values.toList();
  }

  List<ShellWorkspacePreference> _legacyWorkspacePreferences(Settings settings) {
    final sectionIds = _config.destinations.map((destination) => destination.id).toSet();
    if (settings.shellTabs.isEmpty || sectionIds.isEmpty) return const [];
    final fallback = sectionIds.contains(settings.selectedActivityId)
        ? settings.selectedActivityId!
        : _config.destinations.first.id;
    final grouped = <String, List<ShellTabPreference>>{};
    for (final tab in settings.shellTabs) {
      final sectionId = [
        tab.sectionId,
        tab.destinationId,
      ].whereType<String>().firstWhere(sectionIds.contains, orElse: () => fallback);
      grouped.putIfAbsent(sectionId, () => []).add(tab.copyWith(sectionId: sectionId));
    }
    return [
      for (final entry in grouped.entries)
        ShellWorkspacePreference(
          sectionId: entry.key,
          tabs: entry.value,
          activeTabId: entry.value.any((tab) => tab.id == settings.selectedShellTabId)
              ? settings.selectedShellTabId
              : entry.value.firstOrNull?.id,
        ),
    ];
  }

  String? _defaultViewId(String sectionId) {
    final section = _navigation.sectionFor(sectionId);
    final configured = section?.defaultViewId;
    if (configured != null && _navigation.canOpenView(sectionId, configured)) return configured;
    final associated = _navigation
        .viewsForSection(sectionId)
        .where((view) => view.destinationId == sectionId)
        .firstOrNull;
    return associated?.id;
  }

  void _ensureSectionDefaultView(String sectionId, {bool activateSection = true}) {
    if (_navigation.workspaceFor(sectionId).tabs.isNotEmpty) return;
    final registrationId = _defaultViewId(sectionId);
    if (registrationId != null) {
      _navigation.openTab(sectionId, registrationId, activateSection: activateSection);
    }
  }

  ShellViewRegistration? _viewFor(String registrationId) => _navigation.registrationFor(registrationId);

  void setSwipeDisabled({bool disableSwipe = false}) {
    setState(() => swipeDisabled = disableSwipe);
  }

  Future<bool> selectedPage(String id) async {
    final destination = _destinations.where((item) => item.id == id).firstOrNull;
    if (destination == null) return false;
    final wasSelected = selectedActivityId == id;
    if (destination.isUtility && !wasSelected) {
      _returnSectionId = _navigation.sectionFor(selectedActivityId)?.isUtility == false
          ? selectedActivityId
          : _returnSectionId;
    } else if (!destination.isUtility) {
      _returnSectionId = id;
    }
    if (!wasSelected) {
      setState(() => _activityPanelOpen = destination.panelBuilder != null);
    }
    _navigation.selectSection(id);
    _ensureSectionDefaultView(id);
    if (destination.openViewId case final viewId?) _navigation.openTab(id, viewId);
    if (destination.commandId case final commandId?) {
      final command = _config.commands.where((item) => item.id == commandId).firstOrNull;
      if (command != null) {
        await command.run(context);
        if (!mounted) return false;
      }
    }
    if (destination.onSelected case final action?) {
      await action(context);
      if (!mounted) return false;
    }
    _announce(destination.title(context));
    return true;
  }

  Future<void> _navigateSection(String id) async {
    await selectedPage(id);
  }

  Future<void> _navigateTab(String sectionId, String tabId) async {
    if (!await selectedPage(sectionId)) return;
    _navigation.selectTab(sectionId, tabId);
  }

  void _toggleActivityPanel() {
    setState(() => _activityPanelOpen = !_activityPanelOpen);
  }

  void _updateBrowserRoute(String path) {
    if (!kIsWeb || _handlingPlatformRoute || _lastPushedRouteId == path) return;
    _lastPushedRouteId = path;
    unawaited(SystemNavigator.routeInformationUpdated(uri: Uri.parse(path)));
  }

  void _handleBrowserRoute(RouteInformation routeInformation) {
    final uri = routeInformation.uri;
    final route = _navigation.views.where((view) => view.routePath == uri.path).firstOrNull;
    final activityId = _destinations.any((destination) => destination.id == uri.pathSegments.lastOrNull)
        ? uri.pathSegments.last
        : null;
    if (route == null && activityId == null) return;
    _handlingPlatformRoute = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (route != null) {
        final sectionId = route.destinationId != null && _navigation.sectionFor(route.destinationId!) != null
            ? route.destinationId!
            : selectedActivityId;
        _navigation.openTab(sectionId, route.id, instanceId: 'route');
        _handlingPlatformRoute = false;
      } else {
        unawaited(selectedPage(activityId!).whenComplete(() => _handlingPlatformRoute = false));
      }
    });
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final routeInformation = widget.routeInformation;
    if (routeInformation != null && routeInformation != oldWidget.routeInformation) {
      _handleBrowserRoute(routeInformation);
    }
  }

  Widget _activeContent() {
    final sections = _navigation.sections;
    if (sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.noTabsOpen),
            const SizedBox(height: 8),
            FilledButton(onPressed: _showViewPicker, child: Text(context.l10n.openViewTab)),
          ],
        ),
      );
    }
    final index = sections.indexWhere((section) => section.id == selectedActivityId).clamp(0, sections.length - 1);
    return IndexedStack(index: index, children: [for (final section in sections) _sectionContent(section.id)]);
  }

  Widget _sectionContent(String sectionId) {
    final workspace = _navigation.workspaceFor(sectionId);
    final index = workspace.tabs.indexWhere((tab) => tab.id == workspace.activeTabId);
    if (index < 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.noTabsOpen),
            if (_navigation.viewsForSection(sectionId).isNotEmpty) ...[
              const SizedBox(height: 8),
              FilledButton(onPressed: _showViewPicker, child: Text(context.l10n.openViewTab)),
            ],
          ],
        ),
      );
    }
    return IndexedStack(
      key: ValueKey('section-tabs-$sectionId'),
      index: index,
      children: [
        for (final tab in workspace.tabs)
          KeyedSubtree(
            key: ValueKey('workspace-tab-${tab.id}'),
            child: TickerMode(
              enabled: sectionId == selectedActivityId && tab.id == workspace.activeTabId,
              child: _registeredViewContent(tab),
            ),
          ),
      ],
    );
  }

  Widget _registeredViewContent(ShellTabPreference tab) {
    final registration = _viewFor(tab.registrationId);
    if (registration == null || !registration.hasBuilder) {
      return ShellContentSlot(state: ShellSlotState.unavailable, message: context.l10n.shellMissingView);
    }
    final runtime = _runtimeFor(tab);
    return Navigator(
      key: runtime.navigatorKey,
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (context) {
          try {
            return registration.buildContent(context, runtime.viewContext(tab, widget.mainNavigatorKey));
          } catch (error) {
            return ShellContentSlot(state: ShellSlotState.error, message: context.l10n.shellContentError('$error'));
          }
        },
      ),
    );
  }

  String? openView(
    String registrationId, {
    String? sectionId,
    String? instanceId,
    Map<String, dynamic> parameters = const {},
    String? title,
    bool activateSection = true,
  }) => _navigation.openView(
    registrationId,
    sectionId: sectionId,
    instanceId: instanceId,
    parameters: parameters,
    title: title,
    activateSection: activateSection,
  );

  void _openRegisteredView(ShellViewRegistration registration) =>
      _navigation.openView(registration.id, sectionId: registration.destinationId);

  Future<void> _closeTab(ShellTabPreference tab) async {
    final registration = _viewFor(tab.registrationId);
    if (registration?.closeable == false) return;
    final sectionId = tab.sectionId ?? selectedActivityId;
    final runtime = _tabRuntimes[tab.id];
    final wasActive = tab.id == _selectedTabId;
    runtime?.lifecycle.value = ShellTabLifecycle.closing;
    final allowed = registration?.onCloseRequested != null
        ? await registration!.onCloseRequested!(context, tab)
        : !tab.isDirty || await _confirmCloseDirtyTab(tab);
    if (!allowed || !mounted) {
      if (runtime != null) {
        runtime.lifecycle.value = wasActive ? ShellTabLifecycle.activated : ShellTabLifecycle.deactivated;
      }
      return;
    }
    _navigation.closeTab(sectionId, tab.id, closable: true);
  }

  void _reorderTabs(int oldIndex, int newIndex) => _navigation.reorderTabs(selectedActivityId, oldIndex, newIndex);

  void _moveTab(ShellTabPreference tab, int offset) =>
      _navigation.moveTab(tab.sectionId ?? selectedActivityId, tab.id, offset);

  String _tabTitle(ShellTabPreference tab) {
    final registration = _viewFor(tab.registrationId);
    return tab.title ?? registration?.title(context, tab.instanceId ?? tab.id) ?? context.l10n.shellMissingView;
  }

  IconData? _tabIcon(ShellTabPreference tab) => _viewFor(tab.registrationId)?.icon;

  Future<bool> _confirmCloseDirtyTab(ShellTabPreference tab) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.closeUnsavedTabTitle),
          content: Text(context.l10n.closeUnsavedTabMessage(_tabTitle(tab))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.closeTab)),
          ],
        ),
      ) ??
      false;

  _ShellTabRuntime _runtimeFor(ShellTabPreference tab) => _tabRuntimes.putIfAbsent(tab.id, () {
    final runtime = _ShellTabRuntime(
      tab: tab,
      isRestored: _restoringSettings,
      initialNavigationPath: tab.navigationPath,
      initialRightSidebarOpen: tab.inspectorOpen,
      initialSplitOpen: tab.splitOpen ?? _settingsController.settings.splitOpen,
      hasSplitPreference: tab.splitOpen != null,
      initialSplitWeights: tab.splitWeights,
      openView: _openViewFromContext,
      activateTab: _activateTabFromContext,
      closeTab: _closeTabFromContext,
      selectSection: selectedPage,
      updateTab: _updateTabFromContext,
    );
    runtime.breadcrumbs.addListener(() => _handleBreadcrumbChanged(tab, runtime.breadcrumbs));
    for (final controller in runtime.controllers) {
      controller.addListener(_handleStatusChanged);
    }
    return runtime;
  });

  void _updateTabFromContext(String tabId, ShellTabPreference Function(ShellTabPreference) update) {
    final tab = _navigation.workspaceContaining(tabId)?.tabs.where((candidate) => candidate.id == tabId).firstOrNull;
    if (tab != null) _navigation.updateTab(update(tab));
  }

  Future<String?> _openViewFromContext(
    String registrationId, {
    String? sectionId,
    String? instanceId,
    Map<String, dynamic> parameters = const {},
    String? title,
  }) async {
    final targetSectionId = sectionId ?? selectedActivityId;
    if (_navigation.sectionFor(targetSectionId) == null) return null;
    await selectedPage(targetSectionId);
    return _navigation.openTab(
      targetSectionId,
      registrationId,
      instanceId: instanceId,
      parameters: parameters,
      title: title,
    );
  }

  Future<bool> _activateTabFromContext(String sectionId, String tabId) async {
    if (_navigation.workspaceFor(sectionId).tabs.every((tab) => tab.id != tabId)) return false;
    await selectedPage(sectionId);
    _navigation.selectTab(sectionId, tabId);
    return _navigation.activeTab?.id == tabId;
  }

  Future<bool> _closeTabFromContext(String tabId) async {
    final tab = _navigation.workspaceContaining(tabId)?.tabs.where((candidate) => candidate.id == tabId).firstOrNull;
    if (tab == null) return false;
    await _closeTab(tab);
    return _navigation.workspaceContaining(tabId) == null;
  }

  void _handleBreadcrumbChanged(ShellTabPreference tab, ShellBreadcrumbController breadcrumbs) {
    if (!mounted) return;
    final currentTab = _navigation
        .workspaceContaining(tab.id)
        ?.tabs
        .where((candidate) => candidate.id == tab.id)
        .firstOrNull;
    if (currentTab == null || listEquals(currentTab.navigationPath, breadcrumbs.activePathIds)) return;
    _navigation.updateTabNavigationPath(currentTab.sectionId ?? selectedActivityId, tab.id, breadcrumbs.activePathIds);
  }

  ShellViewContext _viewContextFor(ShellTabPreference tab) =>
      _runtimeFor(tab).viewContext(tab, widget.mainNavigatorKey);

  void _syncTabRuntimes() {
    final tabIds = _allTabs.map((tab) => tab.id).toSet();
    for (final id in _tabRuntimes.keys.where((id) => !tabIds.contains(id)).toList()) {
      final runtime = _tabRuntimes.remove(id)!;
      runtime.lifecycle.value = ShellTabLifecycle.closed;
      for (final controller in runtime.controllers) {
        controller.removeListener(_handleStatusChanged);
      }
      runtime.dispose();
    }
    for (final tab in _allTabs) {
      final runtime = _runtimeFor(tab);
      runtime.rightSidebar.restoreVisibility(isVisible: tab.inspectorOpen);
      runtime.workspace.restoreLayout(
        isOpen: tab.splitOpen ?? _settingsController.settings.splitOpen,
        hasPreference: tab.splitOpen != null,
        weights: tab.splitWeights,
      );
    }
    if (_lastLifecycleActiveId != _selectedTabId) {
      if (_lastLifecycleActiveId case final previousId?) {
        _tabRuntimes[previousId]?.lifecycle.value = ShellTabLifecycle.deactivated;
      }
      if (_selectedTabId case final activeId?) {
        _tabRuntimes[activeId]?.lifecycle.value = ShellTabLifecycle.activated;
      }
      _lastLifecycleActiveId = _selectedTabId;
    }
  }

  void _handleSettingsChanged() {
    if (!mounted || !_settingsWired) return;
    final settings = _settingsController.settings;
    _restoringSettings = true;
    _navigation.restoreWorkspaces(_workspacePreferences(settings), selectedSectionId: _restoredSectionId(settings));
    _restoringSettings = false;
    setState(() {
      _splitRatio = settings.splitRatio;
    });
    _syncTabRuntimes();
    _syncStatusProviders();
  }

  void _handleNavigationChanged() {
    _syncTabRuntimes();
    _syncStatusProviders();
    if (!mounted || !_settingsWired || _restoringSettings) return;
    setState(() {});
    final active = _activeTab;
    final settings = _settingsController.settings;
    final workspaces = _navigation.workspaces.map((workspace) => workspace.toPreference()).toList();
    _settingsController.update(
      settings.copyWith(
        shellWorkspaces: workspaces,
        shellTabs: _allTabs,
        selectedShellTabId: _selectedTabId ?? '',
        selectedActivityId: _navigation.selectedSectionId ?? settings.selectedActivityId,
        splitOpen: active?.splitOpen ?? settings.splitOpen,
      ),
    );
    final routePath = active == null ? null : _viewFor(active.registrationId)?.routePath;
    if (routePath != null) _updateBrowserRoute(routePath);
    if (_selectedTabId case final selectedId?) _scrollTabIntoView(selectedId);
  }

  void _scrollTabIntoView(String selectedId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _tabKeys[selectedId]?.currentContext;
      if (target != null) {
        unawaited(Scrollable.ensureVisible(target));
        return;
      }
      if (!_tabScrollController.hasClients) return;
      final index = _tabs.indexWhere((tab) => tab.id == selectedId);
      if (index < 0) return;
      final position = _tabScrollController.position;
      _tabScrollController.jumpTo(index < _tabs.length / 2 ? position.minScrollExtent : position.maxScrollExtent);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final visibleTarget = _tabKeys[selectedId]?.currentContext;
        if (mounted && visibleTarget != null) unawaited(Scrollable.ensureVisible(visibleTarget));
      });
    });
  }

  void _syncStatusProviders() {
    final currentTabIds = _allTabs.map((tab) => tab.id).toSet();
    _tabKeys.removeWhere((id, _) => !currentTabIds.contains(id));
    for (final id in _statusProviders.keys.where((id) {
      final tab = _allTabs.where((tab) => tab.id == id).firstOrNull;
      return tab == null || _viewFor(tab.registrationId)?.statusProviderFactory == null;
    }).toList()) {
      final provider = _statusProviders.remove(id)!;
      provider.removeListener(_handleStatusChanged);
      provider.dispose();
    }
    for (final tab in _allTabs) {
      final factory = _viewFor(tab.registrationId)?.statusProviderFactory;
      if (factory != null && !_statusProviders.containsKey(tab.id)) {
        final provider = factory(tab.instanceId ?? tab.id);
        provider.addListener(_handleStatusChanged);
        _statusProviders[tab.id] = provider;
      }
      _tabKeys.putIfAbsent(tab.id, GlobalKey.new);
    }
  }

  void _handleStatusChanged() {
    if (!mounted) return;
    void refresh() {
      _statusRefreshScheduled = false;
      if (!mounted) return;
      setState(() {});
      final rightSidebar = _activeTab == null ? null : _tabRuntimes[_activeTab!.id]?.rightSidebar;
      if (rightSidebar?.isVisible == true && MediaQuery.sizeOf(context).width < 1200 && !_rightSidebarDrawerOpen) {
        _scaffoldKey.currentState?.openEndDrawer();
      }
    }

    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      refresh();
      return;
    }
    if (_statusRefreshScheduled) return;
    _statusRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
  }

  @override
  void initState() {
    super.initState();
    final supplied = widget.config ?? defaultShellConfig();
    final views = [...supplied.views];
    for (final (id, fallbackTitle, icon, fallbackBuilder) in [
      (
        'profile',
        (BuildContext buildContext, _) => buildContext.l10n.profile,
        Icons.person_outline,
        (BuildContext buildContext, _) => _buildProfileView(buildContext),
      ),
      (
        'settings',
        (BuildContext buildContext, _) => buildContext.l10n.settingsTitle,
        Icons.settings_outlined,
        (BuildContext buildContext, _) => _buildSettingsView(buildContext),
      ),
    ]) {
      final registration = views.where((view) => view.id == id).firstOrNull;
      views.removeWhere((view) => view.id == id);
      views.add(
        ShellViewRegistration(
          id: id,
          title: registration?.title ?? fallbackTitle,
          viewBuilder: registration?.viewBuilder ?? fallbackBuilder,
          destinationId: id,
          icon: registration?.icon ?? icon,
          routePath: registration?.routePath,
          reusePolicy: id == 'settings'
              ? registration?.reusePolicy ?? ShellViewReusePolicy.never
              : ShellViewReusePolicy.byRegistration,
          closeable: registration?.closeable ?? true,
          rightSidebarBuilder: registration?.rightSidebarBuilder,
          inspectorBuilder: registration?.inspectorBuilder,
        ),
      );
    }
    for (final context in supplied.contexts) {
      for (final module in context.modules) {
        views.add(
          ShellViewRegistration(
            id: 'module.${context.id}.${module.id}',
            title: (buildContext, _) => module.title(buildContext),
            viewBuilder: (buildContext, _) => module.builder(buildContext),
            contextId: context.id,
            moduleId: module.id,
          ),
        );
      }
    }
    for (final module in supplied.modules) {
      views.add(
        ShellViewRegistration(
          id: 'module.${module.id}',
          title: (buildContext, _) => module.title(buildContext),
          viewBuilder: (buildContext, _) => module.builder(buildContext),
          moduleId: module.id,
        ),
      );
    }
    final destinations = supplied.destinations
        .where((destination) => destination.id != 'profile' && destination.id != 'settings')
        .toList();
    for (final (id, icon, showOnMobile, fallbackTitle) in [
      ('profile', Icons.person_outline, true, (BuildContext buildContext) => buildContext.l10n.profile),
      ('settings', Icons.settings_outlined, true, (BuildContext buildContext) => buildContext.l10n.settingsTitle),
    ]) {
      final suppliedDestination = supplied.destinations.where((destination) => destination.id == id).firstOrNull;
      destinations.add(
        ShellDestination(
          id: id,
          title: suppliedDestination?.title ?? fallbackTitle,
          icon: suppliedDestination?.icon ?? icon,
          inactiveIcon: suppliedDestination?.inactiveIcon ?? icon,
          lockedVisible: true,
          isUtility: true,
          showOnMobile: suppliedDestination?.showOnMobile ?? showOnMobile,
          defaultViewId: id,
          allowedViewIds: {id},
          panelBuilder: suppliedDestination?.panelBuilder,
          rightSidebarBuilder: suppliedDestination?.rightSidebarBuilder,
          inspectorBuilder: suppliedDestination?.inspectorBuilder,
          statusItemsBuilder: suppliedDestination?.statusItemsBuilder,
          statusProvider: suppliedDestination?.statusProvider,
          onSelected: suppliedDestination?.onSelected,
        ),
      );
    }
    _config = ShellConfig(
      title: supplied.title,
      destinations: destinations,
      views: views,
      modules: supplied.modules,
      contexts: supplied.contexts,
      commands: supplied.commands,
      globalStatusProviders: supplied.globalStatusProviders,
      rightSidebarBuilder: supplied.rightSidebarBuilder,
      inspectorBuilder: supplied.inspectorBuilder,
      splitPaneBuilder: supplied.splitPaneBuilder,
    );
    _sharedStatusProviders.addAll(supplied.globalStatusProviders);
    _sharedStatusProviders.addAll(
      destinations.map((destination) => destination.statusProvider).whereType<ShellStatusProvider>(),
    );
    for (final provider in _sharedStatusProviders) {
      provider.addListener(_handleStatusChanged);
    }
    _navigation = ShellNavigationCoordinator(sections: _config.destinations, views: views);
    _navigation.addListener(_handleNavigationChanged);
    for (final destination in _config.destinations) {
      navigatorKeys[destination.id] = GlobalKey<NavigatorState>();
      exitAnimationKeys[destination.id] = GlobalKey<AnimatedExitState>();
      entryAnimationKeys[destination.id] = GlobalKey<AnimatedEntryState>();
    }
    pageController.addListener(() {
      if (mounted) setState(() => pagePosition = pageController.page ?? 0);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_settingsWired) return;
    _settingsController = AppScope.of(context).settings;
    _settingsController.addListener(_handleSettingsChanged);
    final settings = _settingsController.settings;
    final routeUri = widget.routeInformation?.uri;
    final uri = routeUri != null && (routeUri.pathSegments.isNotEmpty || routeUri.fragment.isNotEmpty)
        ? routeUri
        : Uri.base;
    final workspacePreferences = _workspacePreferences(settings);
    _restoringSettings = true;
    _navigation.restoreWorkspaces(workspacePreferences, selectedSectionId: _restoredSectionId(settings));
    if (selectedActivityId.isNotEmpty) _ensureSectionDefaultView(selectedActivityId, activateSection: false);
    _restoringSettings = false;
    _lastPushedRouteId = _activeTab == null ? null : _viewFor(_activeTab!.registrationId)?.routePath;
    _splitRatio = settings.splitRatio;
    _settingsWired = true;
    _syncTabRuntimes();
    _syncStatusProviders();
    if (_selectedTabId case final selectedId?) _scrollTabIntoView(selectedId);
    if (settings.shellWorkspaces.isEmpty ||
        _navigation.workspaces.length != settings.shellWorkspaces.length ||
        _allTabs.length != settings.shellTabs.length ||
        _selectedTabId != settings.selectedShellTabId ||
        selectedActivityId != _restoredSectionId(settings)) {
      final migrated = settings.copyWith(
        shellWorkspaces: _navigation.workspaces.map((workspace) => workspace.toPreference()).toList(),
        shellTabs: _allTabs,
        selectedShellTabId: _selectedTabId ?? '',
        selectedActivityId: selectedActivityId.isEmpty ? null : selectedActivityId,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _settingsController.update(migrated);
      });
    }
    if (kIsWeb || routeUri != null) {
      final path = uri.path != '/'
          ? uri.path
          : uri.fragment.isEmpty
          ? null
          : '/${uri.fragment}';
      if (path != null) _handleBrowserRoute(RouteInformation(uri: Uri.parse(path)));
    }
  }

  @override
  void dispose() {
    if (_settingsWired) _settingsController.removeListener(_handleSettingsChanged);
    _navigation.removeListener(_handleNavigationChanged);
    for (final provider in _statusProviders.values) {
      provider.removeListener(_handleStatusChanged);
      provider.dispose();
    }
    for (final provider in _sharedStatusProviders) {
      provider.removeListener(_handleStatusChanged);
    }
    for (final runtime in _tabRuntimes.values) {
      runtime.dispose();
    }
    _tabRuntimes.clear();
    _statusProviders.clear();
    _navigation.dispose();
    pageController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  Future<void> _openSettings() async {
    await selectedPage('settings');
  }

  String? _restoredSectionId(Settings settings) {
    if (settings.selectedActivityId != 'page6') return settings.selectedActivityId;
    final savedTabs = [...settings.shellTabs, ...settings.shellWorkspaces.expand((workspace) => workspace.tabs)];
    return savedTabs.any((tab) => tab.id == settings.selectedShellTabId && tab.registrationId == 'settings')
        ? 'settings'
        : settings.selectedActivityId;
  }

  Widget _buildSettingsView(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 44,
        child: Row(
          children: [
            IconButton(
              tooltip: context.l10n.returnToPreviousSection,
              onPressed: _returnToPreviousSection,
              icon: const Icon(Icons.arrow_back),
            ),
            Text(context.l10n.settingsTitle, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
      Expanded(child: buildDefaultSettingsPage()),
    ],
  );

  Widget _buildProfileView(BuildContext context) =>
      ProfileView(appTitle: _config.title(context), onSignIn: _openLogin, showHeader: false);

  void _returnToPreviousSection() {
    final fallback = _navigation.sections.where((destination) => !destination.isUtility).firstOrNull?.id;
    unawaited(selectedPage(_returnSectionId ?? fallback ?? 'settings'));
  }

  void _openLogin() {
    unawaited(
      Navigator.of(
        context,
        rootNavigator: true,
      ).push<void>(MaterialPageRoute(builder: (_) => LoginPage(appTitle: _config.title(context)))),
    );
  }

  void _toggleAppearance() {
    final settings = _settingsController.settings;
    final useDarkmode = settings.useSystemDarkmode
        ? Theme.of(context).brightness != Brightness.dark
        : !settings.useDarkmode;
    _settingsController.update(settings.copyWith(useSystemDarkmode: false, useDarkmode: useDarkmode));
  }

  void _announce(String message) {
    unawaited(SemanticsService.sendAnnouncement(View.of(context), message, Directionality.of(context)));
  }

  void _toggleRightSidebar() {
    _setRightSidebarOpen(!_rightSidebarOpen);
  }

  void _setRightSidebarOpen(bool isOpen) {
    final tab = _activeTab;
    if (tab != null) {
      _runtimeFor(tab).rightSidebar.setVisible(isVisible: isOpen);
      return;
    }
    final workspace = _navigation.activeWorkspace;
    if (workspace.inspectorOpen != null) {
      _navigation.setSectionRightSidebarOpen(selectedActivityId, isOpen: isOpen);
      return;
    }
    _settingsController.update(_settingsController.settings.copyWith(inspectorOpen: isOpen));
  }

  void _toggleSplit() {
    final settings = _settingsController.settings;
    final tab = _activeTab;
    if (tab == null) {
      _settingsController.update(settings.copyWith(splitOpen: !settings.splitOpen));
    } else {
      final workspace = _runtimeFor(tab).workspace;
      if (workspace.panes.isNotEmpty) {
        workspace.setSplitOpen(isOpen: !workspace.isSplitOpen);
      } else {
        _navigation.updateTab(tab.copyWith(splitOpen: !_splitOpen));
      }
    }
  }

  void _resizeSplit(double ratio, {bool persist = false}) {
    final next = ratio.clamp(0.3, 0.7);
    setState(() => _splitRatio = next);
    if (persist) _settingsController.update(_settingsController.settings.copyWith(splitRatio: next));
  }

  void _selectContext(String id) {
    final selected = _config.contexts.where((configured) => configured.id == id).firstOrNull;
    if (selected == null) return;
    _settingsController.update(
      _settingsController.settings.copyWith(selectedContextId: selected.id, selectedModuleId: null),
    );
  }

  void _selectModule(String id) {
    if (!_modules.any((module) => module.id == id)) return;
    _settingsController.update(_settingsController.settings.copyWith(selectedModuleId: id));
    final registration = _moduleView(_selectedContextId, id);
    if (registration != null) _openRegisteredView(registration);
  }

  ShellViewRegistration? _moduleView(String? contextId, String moduleId) =>
      _navigation.views.where((view) => view.contextId == contextId && view.moduleId == moduleId).firstOrNull;

  List<ShellViewAction> get _activeToolbarActions {
    final active = _activeTab;
    final builder = active == null ? null : _viewFor(active.registrationId)?.toolbarActionsBuilder;
    if (active == null) return const [];
    final actions = _tabRuntimes[active.id]?.toolbar.actions ?? const <ShellViewAction>[];
    if (builder == null) return actions;
    try {
      return [...builder(context, _viewContextFor(active)), ...actions];
    } catch (_) {
      return actions;
    }
  }

  void _restoreLayout() {
    final settings = _settingsController.settings;
    final workspaces = [
      for (final workspace in _navigation.workspaces)
        ShellWorkspacePreference(
          sectionId: workspace.sectionId,
          tabs: workspace.tabs.map((tab) => tab.copyWith(inspectorOpen: false, splitOpen: false)).toList(),
          activeTabId: workspace.activeTabId,
          inspectorOpen: false,
        ),
    ];
    _navigation.restoreWorkspaces(workspaces, selectedSectionId: selectedActivityId);
    _settingsController.update(
      settings.copyWith(
        inspectorOpen: false,
        inspectorWidth: 320,
        splitOpen: false,
        splitRatio: 0.5,
        shellWorkspaces: workspaces,
        shellTabs: _allTabs,
      ),
    );
    _announce(context.l10n.restoreLayout);
  }

  Future<void> _showNotificationsPanel() =>
      showShellNotifications(context, AppScope.of(context).services.shellNotifications, phone: _isPhoneLayout);

  List<ShellPaletteCommand> _commands() {
    final commands = <ShellPaletteCommand>[
      if (_config.destinations.any((item) => item.id == 'settings' || item.id == 'page6'))
        ShellPaletteCommand(id: 'settings', title: context.l10n.openSettings, shortcut: '', run: _openSettings),
      ShellPaletteCommand(
        id: 'right-sidebar',
        title: _rightSidebarOpen ? context.l10n.closeRightSidebar : context.l10n.openRightSidebar,
        shortcut: '',
        run: _openRightSidebar,
      ),
      if (_hasSplitContent)
        ShellPaletteCommand(
          id: 'split',
          title: _splitOpen ? context.l10n.closeSplitView : context.l10n.openSplitView,
          shortcut: '',
          run: _toggleSplit,
        ),
      ShellPaletteCommand(
        id: 'notifications',
        title: context.l10n.openNotifications,
        shortcut: '',
        run: _showNotificationsPanel,
      ),
      ShellPaletteCommand(id: 'layout', title: context.l10n.restoreLayout, shortcut: '', run: _restoreLayout),
      ShellPaletteCommand(id: 'theme', title: context.l10n.toggleAppearance, shortcut: '', run: _toggleAppearance),
      ShellPaletteCommand(id: 'new-tab', title: context.l10n.newTab, shortcut: '', run: _openNewTab),
      ShellPaletteCommand(id: 'open-view-picker', title: context.l10n.openViewTab, shortcut: '', run: _showViewPicker),
      for (final command in _config.commands)
        ShellPaletteCommand(
          id: command.id,
          title: command.title(context),
          shortcut: '',
          run: () async => command.run(context),
        ),
    ];
    for (final view in _navigation.viewsForSection(selectedActivityId)) {
      commands.add(
        ShellPaletteCommand(
          id: 'open-view-${view.id}',
          title: context.l10n.openView(view.title(context, view.id)),
          shortcut: '',
          run: () => _navigation.openTab(selectedActivityId, view.id),
        ),
      );
    }
    for (final tab in _tabs) {
      commands.add(
        ShellPaletteCommand(
          id: 'tab-${tab.id}',
          title: '${context.l10n.switchView}: ${_tabTitle(tab)}',
          shortcut: '',
          run: () => _navigation.selectTab(selectedActivityId, tab.id),
        ),
      );
    }
    for (final destination in _destinations) {
      commands.add(
        ShellPaletteCommand(
          id: 'navigate-${destination.id}',
          title: context.l10n.navigateTo(destination.title(context)),
          shortcut: '',
          run: () => selectedPage(destination.id),
        ),
      );
    }
    for (final configured in _config.contexts) {
      commands.add(
        ShellPaletteCommand(
          id: 'context-${configured.id}',
          title: context.l10n.switchContext(configured.title(context)),
          shortcut: '',
          run: () => _selectContext(configured.id),
        ),
      );
    }
    for (final module in _modules) {
      commands.add(
        ShellPaletteCommand(
          id: 'module-${module.id}',
          title: context.l10n.switchModule(module.title(context)),
          shortcut: '',
          run: () => _selectModule(module.id),
        ),
      );
    }
    return commands;
  }

  Future<void> _showCommandPalette() async {
    await showDialog<void>(
      context: context,
      builder: (_) => ShellCommandPaletteDialog(commands: _commands()),
    );
  }

  bool _isTextInputFocused() {
    final focused = FocusManager.instance.primaryFocus?.context;
    return focused?.widget is EditableText;
  }

  void _runShellShortcut(FutureOr<void> Function() action) {
    if (_isTextInputFocused()) return;
    unawaited(Future<void>.sync(action));
  }

  void _selectTabIndex(int index) {
    if (index >= 0 && index < _tabs.length) _navigation.selectTab(selectedActivityId, _tabs[index].id);
  }

  void _selectRelativeTab(int offset) {
    if (_tabs.isEmpty) return;
    final index = _tabs.indexWhere((tab) => tab.id == _selectedTabId);
    _selectTabIndex((index + offset + _tabs.length) % _tabs.length);
  }

  Future<void> _closeActiveTab() async {
    final tab = _activeTab;
    if (tab != null) await _closeTab(tab);
  }

  Future<void> _showViewPicker() async {
    final views = _navigation.viewsForSection(selectedActivityId);
    if (views.isEmpty) return;
    final selected = await showDialog<ShellViewRegistration>(
      context: context,
      builder: (_) => ShellViewPickerDialog(views: views, title: _viewTitle),
    );
    if (selected != null) _navigation.openTab(selectedActivityId, selected.id);
  }

  void _openNewTab() {
    final sectionId = selectedActivityId;
    final current = _activeTab;
    final registrationId = current?.registrationId ?? _navigation.sectionFor(sectionId)?.defaultViewId;
    if (registrationId != null && _navigation.canOpenView(sectionId, registrationId)) {
      _navigation.openTab(sectionId, registrationId, forceNew: true);
    }
  }

  Future<void> _showOpenTabsSearch() async {
    final selected = await showDialog<ShellTabPreference>(
      context: context,
      builder: (_) => ShellOpenTabsSearchDialog(
        tabs: _allTabs,
        title: _tabTitle,
        sectionTitle: (tab) => _navigation.sectionFor(tab.sectionId ?? tab.destinationId ?? '')?.title(context) ?? '',
      ),
    );
    if (selected != null) {
      _navigation.selectTab(selected.sectionId ?? selected.destinationId ?? selectedActivityId, selected.id);
    }
  }

  String _viewTitle(ShellViewRegistration registration) {
    return registration.title(context, registration.id);
  }

  Future<void> _maybePopCurrentPage() async {
    final navigator = _activeTab == null ? null : _tabRuntimes[_activeTab!.id]?.navigatorKey.currentState;
    await (navigator ?? widget.mainNavigatorKey.currentState)?.maybePop();
  }

  void _openRightSidebar() {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 1200) {
      if (_rightSidebarDrawerOpen) {
        _setRightSidebarOpen(false);
        _scaffoldKey.currentState?.closeEndDrawer();
      } else {
        _setRightSidebarOpen(true);
        _scaffoldKey.currentState?.openEndDrawer();
      }
    } else {
      _toggleRightSidebar();
    }
  }

  Widget _shellSurface(Widget child) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppShellTokens>();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tokens?.surface ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens?.border ?? theme.dividerColor),
      ),
      child: child,
    );
  }

  Widget _buildHeader(double width, AppShellMetrics metrics, {required bool phone}) {
    final theme = Theme.of(context);
    final actionSize = phone
        ? metrics.targetSize
        : (Theme.of(context).extension<AppShellTokens>()?.comfortable == true ? 36.0 : 32.0);
    final actionIconSize = phone ? 24.0 : 18.0;
    final shortcut = defaultTargetPlatform == TargetPlatform.macOS ? '⌘K' : (kIsWeb ? 'Ctrl+Shift+K' : 'Ctrl+K');
    final notificationService = AppScope.of(context).services.shellNotifications;
    final viewActions = _activeToolbarActions;
    Widget headerAction(String id, Widget child) => Padding(
      padding: const EdgeInsets.only(left: 4),
      child: SizedBox.square(key: ValueKey('header-action-$id'), dimension: actionSize, child: child),
    );

    return IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: Size.square(actionSize),
          maximumSize: Size.square(actionSize),
          iconSize: actionIconSize,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ),
      child: SizedBox(
        height: metrics.headerHeight,
        child: Row(
          children: [
            if (width >= 800)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_config.title(context), style: theme.textTheme.titleMedium),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: width < 800 ? 8 : 0),
                child: _activeTab == null
                    ? Text(
                        _destinations.where((item) => item.id == selectedActivityId).firstOrNull?.title(context) ??
                            _config.title(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            if (_config.contexts.isNotEmpty) _buildContextPicker(width, metrics.menuRowHeight),
            if (_modules.isNotEmpty)
              headerAction(
                'module',
                PopupMenuButton<String>(
                  tooltip: context.l10n.selectModule,
                  padding: EdgeInsets.zero,
                  iconSize: actionIconSize,
                  onSelected: _selectModule,
                  itemBuilder: (context) => _modules
                      .map(
                        (module) => PopupMenuItem(
                          height: metrics.menuRowHeight,
                          value: module.id,
                          child: Text(module.title(context)),
                        ),
                      )
                      .toList(),
                  icon: const Icon(Icons.widgets_outlined),
                ),
              ),
            for (final action in viewActions)
              headerAction(
                'view-action-${action.id}',
                IconButton(
                  tooltip: action.label,
                  onPressed: action.onPressed,
                  icon: Icon(action.icon ?? Icons.bolt_outlined),
                ),
              ),
            if (_tabs.length > 1 && width < 1200)
              headerAction(
                'switch-view',
                PopupMenuButton<String>(
                  tooltip: context.l10n.switchView,
                  padding: EdgeInsets.zero,
                  iconSize: actionIconSize,
                  onSelected: (id) => _navigation.selectTab(selectedActivityId, id),
                  itemBuilder: (context) => _tabs
                      .map(
                        (tab) =>
                            PopupMenuItem(height: metrics.menuRowHeight, value: tab.id, child: Text(_tabTitle(tab))),
                      )
                      .toList(),
                  icon: const Icon(Icons.tab),
                ),
              ),
            if (!phone)
              if (_activeSection?.panelBuilder != null)
                headerAction(
                  'activity-panel',
                  IconButton(
                    tooltip: _activityPanelOpen ? context.l10n.closeSectionPanel : context.l10n.openSectionPanel,
                    onPressed: _toggleActivityPanel,
                    icon: const Icon(Icons.menu_open),
                  ),
                ),
            headerAction(
              'right-sidebar',
              IconButton(
                tooltip: _rightSidebarOpen ? context.l10n.closeRightSidebar : context.l10n.openRightSidebar,
                onPressed: _openRightSidebar,
                icon: Icon(_rightSidebarOpen ? Icons.vertical_split : Icons.vertical_split_outlined),
              ),
            ),
            if (phone)
              headerAction('notifications', ShellNotificationsAction(service: notificationService, phone: true)),
            headerAction(
              'command-palette',
              IconButton(
                tooltip: '${context.l10n.commandPalette} ($shortcut)',
                onPressed: _showCommandPalette,
                icon: const Icon(Icons.terminal),
              ),
            ),
            headerAction(
              'search-tabs',
              IconButton(
                tooltip: context.l10n.searchOpenTabs,
                onPressed: _showOpenTabsSearch,
                icon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildContextPicker(double width, double menuRowHeight) {
    final selected = _selectedContext;
    if (selected == null) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: context.l10n.selectContext,
      onSelected: _selectContext,
      itemBuilder: (context) => _config.contexts
          .map(
            (configured) =>
                PopupMenuItem(height: menuRowHeight, value: configured.id, child: Text(configured.title(context))),
          )
          .toList(),
      child: Semantics(
        button: true,
        label: context.l10n.selectContext,
        value: selected.title(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (width < 800)
                const Icon(Icons.workspaces_outlined, size: 20)
              else
                Text(selected.title(context), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabStrip(AppShellMetrics metrics) {
    final compact = Theme.of(context).extension<AppShellTokens>()?.comfortable != true;
    final actionSize = compact ? 32.0 : 36.0;
    Widget tabAction({
      required Key key,
      required String tooltip,
      required IconData icon,
      required VoidCallback? onPressed,
    }) => Padding(
      padding: const EdgeInsets.only(left: 4),
      child: SizedBox.square(
        dimension: actionSize,
        child: IconButton(
          key: key,
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            minimumSize: Size.square(actionSize),
            maximumSize: Size.square(actionSize),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            iconSize: compact ? 16 : 18,
          ),
        ),
      ),
    );
    return SizedBox(
      height: metrics.tabHeight,
      child: Row(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              scrollController: _tabScrollController,
              buildDefaultDragHandles: false,
              itemCount: _tabs.length,
              onReorderItem: _reorderTabs,
              itemBuilder: (context, index) {
                final tab = _tabs[index];
                return ReorderableDragStartListener(
                  key: _tabKeys.putIfAbsent(tab.id, GlobalKey.new),
                  index: index,
                  child: ShellDesktopTab(
                    title: _tabTitle(tab),
                    icon: _tabIcon(tab),
                    selected: tab.id == _selectedTabId,
                    closable: _viewFor(tab.registrationId)?.closeable ?? true,
                    onSelect: () => _navigation.selectTab(selectedActivityId, tab.id),
                    onClose: () => unawaited(_closeTab(tab)),
                    onContextMenu: (position) => _showTabMenu(tab, position),
                  ),
                );
              },
            ),
          ),
          tabAction(
            key: const ValueKey('tab-overflow-action'),
            tooltip: context.l10n.openTabOverflow,
            icon: Icons.more_horiz,
            onPressed: _tabs.isEmpty ? null : _showTabOverflow,
          ),
          tabAction(
            key: const ValueKey('tab-add-action'),
            tooltip: context.l10n.newTab,
            onPressed: _openNewTab,
            icon: Icons.add,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Future<void> _showTabMenu(ShellTabPreference tab, Offset position) async {
    final index = _tabs.indexWhere((item) => item.id == tab.id);
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(value: 'rename', height: 32, child: Text(context.l10n.renameTab)),
        PopupMenuItem(value: 'close', height: 32, child: Text(context.l10n.closeTab)),
        PopupMenuItem(value: 'closeOthers', height: 32, child: Text(context.l10n.closeOtherTabs)),
        PopupMenuItem(value: 'closeRight', height: 32, child: Text(context.l10n.closeTabsToRight)),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(value: 'left', height: 32, enabled: index > 0, child: Text(context.l10n.moveLeft)),
        PopupMenuItem(
          value: 'right',
          height: 32,
          enabled: index >= 0 && index < _tabs.length - 1,
          child: Text(context.l10n.moveRight),
        ),
      ],
    );
    if (action == 'rename') await _renameTab(tab);
    if (action == 'close') await _closeTab(tab);
    if (action == 'closeOthers') {
      _navigation.selectTab(tab.sectionId ?? selectedActivityId, tab.id);
      for (final other in _tabs.where((item) => item.id != tab.id).toList()) {
        await _closeTab(other);
      }
    }
    if (action == 'closeRight') {
      for (final other in _tabs.skip(index + 1).toList()) {
        await _closeTab(other);
      }
    }
    if (action == 'left') _moveTab(tab, -1);
    if (action == 'right') _moveTab(tab, 1);
  }

  Future<void> _renameTab(ShellTabPreference tab) async {
    final titleField = GlobalKey<FormFieldState<String>>();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.renameTab),
        content: TextFormField(
          key: titleField,
          initialValue: _tabTitle(tab),
          autofocus: true,
          decoration: InputDecoration(labelText: context.l10n.tabTitleLabel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, titleField.currentState?.value?.trim()),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    if (title != null && title.isNotEmpty && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final latest = _navigation.workspaceContaining(tab.id)?.tabs.where((item) => item.id == tab.id).firstOrNull;
        if (latest != null) _navigation.updateTab(latest.copyWith(title: title));
      });
    }
  }

  Future<void> _showTabOverflow() async {
    final id = await showDialog<String>(
      context: context,
      builder: (_) => ShellTabOverflowDialog(tabs: _tabs, title: _tabTitle),
    );
    if (id != null) _navigation.selectTab(selectedActivityId, id);
  }

  Widget _buildActivityPanel(ShellDestination destination) {
    final tokens = Theme.of(context).extension<AppShellTokens>();
    return SizedBox(
      key: const ValueKey('activity-navigation-panel'),
      width: 240,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens?.surface ?? Theme.of(context).colorScheme.surface,
          border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 36,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(child: Text(destination.title(context), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  IconButton(
                    tooltip: context.l10n.closeSectionPanel,
                    onPressed: () => setState(() => _activityPanelOpen = false),
                    icon: const Icon(Icons.close, size: 16),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: destination.panelBuilder!(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildRightSidebar({required bool drawer}) {
    final content = Builder(
      builder: (context) {
        try {
          final active = _activeTab;
          final tabRegistration = active == null ? null : _viewFor(active.registrationId);
          final tabBuilder = tabRegistration?.rightSidebarBuilder ?? tabRegistration?.inspectorBuilder;
          final rightSidebar = active == null ? null : _runtimeFor(active).rightSidebar;
          if (rightSidebar != null && rightSidebar.sections.isNotEmpty) {
            return ShellRightSidebarSections(controller: rightSidebar);
          }
          if (active != null && tabBuilder != null) return tabBuilder(context, _viewContextFor(active));
          final sectionBuilder = _activeSection?.rightSidebarBuilder ?? _activeSection?.inspectorBuilder;
          if (sectionBuilder != null) return sectionBuilder(context);
          final globalBuilder = _config.rightSidebarBuilder ?? _config.inspectorBuilder;
          if (globalBuilder != null) return globalBuilder(context);
          return _defaultRightSidebarContent();
        } catch (error) {
          return Center(child: Text(context.l10n.shellContentError('$error')));
        }
      },
    );
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          SizedBox(
            height: 42,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Expanded(child: Text(context.l10n.rightSidebar, style: Theme.of(context).textTheme.titleSmall)),
                IconButton(
                  tooltip: context.l10n.closeRightSidebar,
                  onPressed: () {
                    _setRightSidebarOpen(false);
                    if (drawer) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _defaultRightSidebarContent() {
    final active = _activeTab;
    final workspace = _navigation.activeWorkspace;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ExpansionTile(
          initiallyExpanded: true,
          title: Text(context.l10n.inspectorWorkspace),
          children: [
            ListTile(
              dense: true,
              title: Text(context.l10n.inspectorSection),
              subtitle: Text(_activeSection?.title(context) ?? ''),
            ),
            ListTile(
              dense: true,
              title: Text(context.l10n.inspectorOpenTabs),
              subtitle: Text('${workspace.tabs.length}'),
            ),
          ],
        ),
        ExpansionTile(
          initiallyExpanded: true,
          title: Text(context.l10n.inspectorSelection),
          children: active == null
              ? [ListTile(dense: true, title: Text(context.l10n.inspectorEmptyState))]
              : [
                  ListTile(dense: true, title: Text(context.l10n.inspectorView), subtitle: Text(_tabTitle(active))),
                  ListTile(
                    dense: true,
                    title: Text(context.l10n.inspectorInstance),
                    subtitle: Text(active.instanceId ?? active.id),
                  ),
                ],
        ),
      ],
    );
  }

  Widget _resizeRightSidebarHandle(double width) {
    void adjust(double delta) {
      final next = (width - delta).clamp(256.0, 440.0);
      _settingsController.update(_settingsController.settings.copyWith(inspectorWidth: next));
    }

    return Semantics(
      button: true,
      label: context.l10n.resizeRightSidebar,
      value: '${width.round()}',
      increasedValue: '${(width + 16).clamp(256.0, 440.0).round()}',
      decreasedValue: '${(width - 16).clamp(256.0, 440.0).round()}',
      onIncrease: () => adjust(-16),
      onDecrease: () => adjust(16),
      child: SizedBox(
        width: 12,
        child: Focus(
          onKeyEvent: (_, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              adjust(-16);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              adjust(16);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            onHorizontalDragUpdate: (details) => adjust(details.delta.dx),
            child: InkWell(
              onTap: () => _settingsController.update(_settingsController.settings.copyWith(inspectorWidth: 320)),
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: Center(child: Icon(Icons.drag_indicator, size: 14, color: Theme.of(context).dividerColor)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplit(Widget primary, double width, {required bool wide}) {
    final active = _activeTab;
    if (active != null) {
      final runtime = _runtimeFor(active);
      if (runtime.workspace.panes.isNotEmpty) {
        return ShellSplitView(primary: primary, view: _viewContextFor(active), workspace: runtime.workspace);
      }
    }
    final builder = _activeSplitBuilder;
    if (!wide || builder == null || !_splitOpen || width < 824) return primary;
    final panelWidth = width - 24;
    final firstFlex = (_splitRatio * 100).round().clamp(30, 70);
    return Row(
      children: [
        Expanded(flex: firstFlex, child: primary),
        Semantics(
          label: context.l10n.resizeSplitPane,
          value: '${(_splitRatio * 100).round()}%',
          increasedValue: '${((_splitRatio + 0.05).clamp(0.3, 0.7) * 100).round()}%',
          decreasedValue: '${((_splitRatio - 0.05).clamp(0.3, 0.7) * 100).round()}%',
          onIncrease: () => _resizeSplit(_splitRatio + 0.05, persist: true),
          onDecrease: () => _resizeSplit(_splitRatio - 0.05, persist: true),
          child: Focus(
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                _resizeSplit(_splitRatio - 0.05, persist: true);
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                _resizeSplit(_splitRatio + 0.05, persist: true);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
              key: const ValueKey('split-divider'),
              onHorizontalDragUpdate: (details) => _resizeSplit(_splitRatio + details.delta.dx / panelWidth),
              onHorizontalDragEnd: (_) =>
                  _settingsController.update(_settingsController.settings.copyWith(splitRatio: _splitRatio)),
              onDoubleTap: () => _resizeSplit(0.5, persist: true),
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: SizedBox(
                  width: 24,
                  child: Center(child: Icon(Icons.drag_indicator, size: 16, color: Theme.of(context).dividerColor)),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 100 - firstFlex,
          child: Builder(
            builder: (context) {
              try {
                final active = _activeTab;
                if (active != null) return builder(context, _viewContextFor(active));
                return _config.splitPaneBuilder?.call(context) ?? const SizedBox.shrink();
              } catch (error) {
                return Center(child: Text(context.l10n.shellContentError('$error')));
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar(AppShellMetrics metrics) {
    final activeTab = _activeTab;
    final controller = activeTab == null ? null : _runtimeFor(activeTab).breadcrumbs;
    return AnimatedBuilder(
      animation: controller ?? _navigation,
      builder: (context, _) {
        final section = _activeSection;
        final sectionId = selectedActivityId;
        final sectionNodeId = 'shell-section:$sectionId';
        final sectionLabel = section?.title(context) ?? _config.title(context);
        final pageRoot = controller?.activePath.firstOrNull;
        final pageDestinations = [
          for (final destination in _destinations)
            (id: destination.id, label: destination.title(context), icon: destination.icon),
        ];
        final breadcrumbs = <ShellNavigationNode>[
          ShellNavigationNode(
            id: sectionNodeId,
            label: sectionLabel,
            icon: section?.icon,
            onActivate: section == null ? null : () => _navigateSection(section.id),
            childrenProvider: _destinations.length > 1
                ? () async {
                    final pageChildren = pageRoot == null
                        ? const <ShellNavigationNode>[]
                        : controller!.hasChildren(pageRoot.id)
                        ? await controller.getChildren(pageRoot.id)
                        : pageRoot.children;
                    return [
                      for (final destination in pageDestinations)
                        ShellNavigationNode(
                          id: 'shell-section:${destination.id}',
                          label: destination.label,
                          icon: destination.icon,
                          onActivate: () => _navigateSection(destination.id),
                          children: destination.id == sectionId ? pageChildren : const [],
                        ),
                    ];
                  }
                : null,
          ),
        ];
        if (activeTab case final tab?) {
          final tabNodeId = 'shell-tab:${tab.id}';
          final workspace = _navigation.workspaceFor(tab.sectionId ?? sectionId);
          final showTab = _tabTitle(tab) != sectionLabel || workspace.tabs.length > 1;
          if (showTab) {
            breadcrumbs.add(
              ShellNavigationNode(
                id: tabNodeId,
                label: _tabTitle(tab),
                icon: _tabIcon(tab),
                parentId: sectionNodeId,
                onActivate: () => _navigateTab(tab.sectionId ?? sectionId, tab.id),
                childrenProvider: workspace.tabs.length > 1
                    ? () async => [
                        for (final sibling in workspace.tabs)
                          ShellNavigationNode(
                            id: 'shell-tab:${sibling.id}',
                            label: _tabTitle(sibling),
                            icon: _tabIcon(sibling),
                            parentId: sectionNodeId,
                            onActivate: () => _navigateTab(sibling.sectionId ?? sectionId, sibling.id),
                          ),
                      ]
                    : null,
              ),
            );
          }
          if (controller != null) {
            final path = controller.activePath;
            final start = path.firstOrNull?.label == sectionLabel ? 1 : 0;
            for (var index = start; index < path.length; index++) {
              final node = controller.activePath[index];
              breadcrumbs.add(
                ShellNavigationNode(
                  id: node.id,
                  label: node.label,
                  icon: node.icon,
                  parentId: index == start
                      ? (showTab ? tabNodeId : sectionNodeId)
                      : node.parentId ?? path[index - 1].id,
                  onActivate: () async => controller.navigateTo(node.id),
                  children: controller.hasChildren(node.id) ? const [] : node.children,
                  childrenProvider: controller.hasChildren(node.id) ? () => controller.getChildren(node.id) : null,
                  enabled: node.enabled,
                  tooltip: node.tooltip,
                  accessibilityLabel: node.accessibilityLabel,
                ),
              );
            }
          }
        } else {
          breadcrumbs.add(
            ShellNavigationNode(
              id: 'shell-empty-workspace:$sectionId',
              label: context.l10n.noTabsOpen,
              parentId: sectionNodeId,
              enabled: false,
            ),
          );
        }

        Future<void> navigate(ShellNavigationNode node) async {
          if (controller?.containsNode(node.id) ?? false) {
            await controller!.navigateTo(node.id);
          } else {
            await node.onActivate?.call();
          }
        }

        final tabItems = [
          ...?_activeStatusProvider?.items,
          if (activeTab != null) ...?_tabRuntimes[activeTab.id]?.status.items,
        ].where((item) => item.isVisible?.call() ?? true).toList();
        final sectionItems = [
          ...?section?.statusItemsBuilder?.call(context),
          ...?section?.statusProvider?.items,
        ].where((item) => item.isVisible?.call() ?? true).toList();
        final globalItems = [for (final provider in _config.globalStatusProviders) ...provider.items]
            .where((item) => item.isVisible?.call() ?? true)
            .toList();
        final notificationService = AppScope.of(context).services.shellNotifications;

        return ShellStatusBar(
          height: metrics.statusHeight,
          menuRowHeight: metrics.menuRowHeight,
          breadcrumbs: breadcrumbs,
          tabItems: tabItems,
          sectionItems: sectionItems,
          globalItems: globalItems,
          onNavigate: navigate,
          notificationControl: ShellNotificationsAction(
            key: const ValueKey('status-notifications'),
            service: notificationService,
            phone: false,
            compact: true,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final baseTheme = Theme.of(context);
    final overlayStyle = SystemUiOverlayStyle(
      statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Theme.of(context).colorScheme.surface,
      systemNavigationBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final phoneLayout = _isPhoneLayout || (kIsWeb && width < 600);
        final shellTheme = phoneLayout
            ? baseTheme.copyWith(
                textTheme: baseTheme.textTheme.copyWith(
                  bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                  labelSmall: baseTheme.textTheme.labelSmall?.copyWith(fontSize: 14),
                  labelMedium: baseTheme.textTheme.labelMedium?.copyWith(fontSize: 15),
                ),
              )
            : baseTheme;
        final wide = width >= 1200;
        final visible = _destinations;
        final settings = _settingsController.settings;
        final metrics = AppTheme.metrics(context, phone: phoneLayout);
        final showRightSidebar = wide && _rightSidebarOpen;
        final availableRightSidebarWidth = (width - metrics.railWidth - 400).clamp(256.0, 440.0);
        final rightSidebarWidth = settings.inspectorWidth.clamp(256.0, availableRightSidebarWidth);
        final body = _activeContent();
        final activeActivity = _destinations.where((item) => item.id == selectedActivityId).firstOrNull;
        final showActivityPanel =
            !phoneLayout && width >= 800 && _activityPanelOpen && activeActivity?.panelBuilder != null;

        return CallbackShortcuts(
          bindings: {
            if (kIsWeb)
              const SingleActivator(LogicalKeyboardKey.keyK, control: true, shift: true): () =>
                  _runShellShortcut(_showCommandPalette),
            if (!kIsWeb && defaultTargetPlatform != TargetPlatform.macOS)
              const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
                  _runShellShortcut(_showCommandPalette),
            if (defaultTargetPlatform == TargetPlatform.macOS)
              const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () => _runShellShortcut(_showCommandPalette),
            if (!kIsWeb) ...{
              SingleActivator(
                LogicalKeyboardKey.keyW,
                control: defaultTargetPlatform != TargetPlatform.macOS,
                meta: defaultTargetPlatform == TargetPlatform.macOS,
              ): () =>
                  _runShellShortcut(_closeActiveTab),
              SingleActivator(
                LogicalKeyboardKey.tab,
                control: defaultTargetPlatform != TargetPlatform.macOS,
                meta: defaultTargetPlatform == TargetPlatform.macOS,
              ): () =>
                  _runShellShortcut(() => _selectRelativeTab(1)),
              SingleActivator(
                LogicalKeyboardKey.tab,
                control: defaultTargetPlatform != TargetPlatform.macOS,
                meta: defaultTargetPlatform == TargetPlatform.macOS,
                shift: true,
              ): () =>
                  _runShellShortcut(() => _selectRelativeTab(-1)),
              for (var index = 0; index < 9; index++)
                SingleActivator(
                  [
                    LogicalKeyboardKey.digit1,
                    LogicalKeyboardKey.digit2,
                    LogicalKeyboardKey.digit3,
                    LogicalKeyboardKey.digit4,
                    LogicalKeyboardKey.digit5,
                    LogicalKeyboardKey.digit6,
                    LogicalKeyboardKey.digit7,
                    LogicalKeyboardKey.digit8,
                    LogicalKeyboardKey.digit9,
                  ][index],
                  control: defaultTargetPlatform != TargetPlatform.macOS,
                  meta: defaultTargetPlatform == TargetPlatform.macOS,
                ): () =>
                    _runShellShortcut(() => _selectTabIndex(index)),
            },
            const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true, shift: true): () =>
                _runShellShortcut(() => _selectRelativeTab(1)),
            const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true, shift: true): () =>
                _runShellShortcut(() => _selectRelativeTab(-1)),
            if (kIsWeb)
              const SingleActivator(LogicalKeyboardKey.keyW, alt: true, shift: true): () =>
                  _runShellShortcut(_closeActiveTab),
          },
          child: Focus(
            autofocus: true,
            // Keep overlay semantics within the shell instead of merging into shortcut focus nodes.
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: overlayStyle,
                child: PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, _) {
                    if (didPop) return;
                    unawaited(_maybePopCurrentPage());
                  },
                  child: Theme(
                    data: shellTheme,
                    child: ShellWorkspace(
                      navigation: _navigation,
                      child: Scaffold(
                        key: _scaffoldKey,
                        resizeToAvoidBottomInset: true,
                        endDrawer: Drawer(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: _shellSurface(_buildRightSidebar(drawer: true)),
                          ),
                        ),
                        onEndDrawerChanged: (isOpen) {
                          _rightSidebarDrawerOpen = isOpen;
                          if (!isOpen && _rightSidebarOpen) _setRightSidebarOpen(false);
                        },
                        body: SafeArea(
                          bottom: false,
                          child: Column(
                            children: [
                              _buildHeader(width, metrics, phone: phoneLayout),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      if (!phoneLayout)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: SideNavBar(
                                            currentId: currentDestinationId,
                                            destinations: visible,
                                            onSelected: (id) => unawaited(selectedPage(id)),
                                          ),
                                        ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _shellSurface(
                                                Column(
                                                  children: [
                                                    if (!phoneLayout) _buildTabStrip(metrics),
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          if (showActivityPanel) _buildActivityPanel(activeActivity!),
                                                          Expanded(
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(8),
                                                              child: LayoutBuilder(
                                                                builder: (context, constraints) =>
                                                                    _buildSplit(body, constraints.maxWidth, wide: wide),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (showRightSidebar) ...[
                                              _resizeRightSidebarHandle(rightSidebarWidth),
                                              const SizedBox(width: 4),
                                              SizedBox(
                                                width: rightSidebarWidth,
                                                child: _shellSurface(_buildRightSidebar(drawer: false)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!phoneLayout) _buildStatusBar(metrics),
                            ],
                          ),
                        ),
                        bottomNavigationBar: phoneLayout
                            ? SafeArea(
                                top: false,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: _shellSurface(
                                    BottomNavBar(
                                      currentId: currentDestinationId,
                                      destinations: visible,
                                      onSelected: (id) => unawaited(selectedPage(id)),
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShellTabRuntime {
  _ShellTabRuntime({
    required this.tab,
    required this.isRestored,
    required List<String> initialNavigationPath,
    required bool? initialRightSidebarOpen,
    required bool initialSplitOpen,
    required bool hasSplitPreference,
    required List<double> initialSplitWeights,
    required ShellOpenView openView,
    required ShellCloseTab closeTab,
    required ShellActivateTab activateTab,
    required ShellSelectSection selectSection,
    required void Function(String, ShellTabPreference Function(ShellTabPreference)) updateTab,
  }) : lifecycle = ValueNotifier(isRestored ? ShellTabLifecycle.restored : ShellTabLifecycle.opened),
       breadcrumbs = ShellBreadcrumbController(initialPath: initialNavigationPath) {
    navigation = ShellNavigationController(
      sectionId: tab.sectionId ?? tab.destinationId ?? '',
      tabId: tab.id,
      openView: openView,
      closeTab: closeTab,
      activateTab: activateTab,
      selectSection: selectSection,
    );
    rightSidebar = ShellRightSidebarController(
      isVisible: initialRightSidebarOpen,
      onVisibilityChanged: (visible) => updateTab(tab.id, (current) => current.copyWith(inspectorOpen: visible)),
    );
    status = ShellStatusController();
    toolbar = ShellToolbarController();
    workspace = ShellWorkspaceController(
      initialSplitOpen: initialSplitOpen,
      hasSplitPreference: hasSplitPreference,
      initialWeights: initialSplitWeights,
      onLayoutChanged: ({required isOpen, required weights, required persist}) {
        if (persist) {
          updateTab(tab.id, (current) => current.copyWith(splitOpen: isOpen, splitWeights: weights));
        }
      },
    );
  }

  final ShellTabPreference tab;
  final bool isRestored;
  final ValueNotifier<ShellTabLifecycle> lifecycle;
  final ShellBreadcrumbController breadcrumbs;
  late final ShellNavigationController navigation;
  late final ShellRightSidebarController rightSidebar;
  late final ShellStatusController status;
  late final ShellToolbarController toolbar;
  late final ShellWorkspaceController workspace;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<AnimatedEntryState> entryAnimationKey = GlobalKey<AnimatedEntryState>();
  final GlobalKey<AnimatedExitState> exitAnimationKey = GlobalKey<AnimatedExitState>();

  List<ChangeNotifier> get controllers => [rightSidebar, status, toolbar, workspace];

  ShellViewContext viewContext(ShellTabPreference tab, GlobalKey<NavigatorState> mainNavigatorKey) => ShellViewContext(
    tab: tab,
    isRestored: isRestored,
    lifecycle: lifecycle,
    breadcrumbs: breadcrumbs,
    mainNavigatorKey: mainNavigatorKey,
    entryAnimationKey: entryAnimationKey,
    exitAnimationKey: exitAnimationKey,
    navigation: navigation,
    rightSidebar: rightSidebar,
    status: status,
    toolbar: toolbar,
    workspace: workspace,
  );

  void dispose() {
    navigation.dispose();
    lifecycle.dispose();
    breadcrumbs.dispose();
    for (final controller in controllers) {
      controller.dispose();
    }
  }
}
