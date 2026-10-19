import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, listEquals, TargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'package:flutter_template/core/app_scope.dart';
import 'package:flutter_template/core/settings.dart';
import 'package:flutter_template/core/themes.dart';
import 'package:flutter_template/l10n/l10n_x.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';
import 'package:flutter_template/pages/home/shell_navigation_coordinator.dart';
import 'package:flutter_template/pages/home/widgets/bottom_nav_bar.dart';
import 'package:flutter_template/pages/home/widgets/page_navigation_animation.dart';
import 'package:flutter_template/pages/home/widgets/shell_notification_center.dart';
import 'package:flutter_template/pages/home/widgets/shell_status_bar.dart';
import 'package:flutter_template/pages/home/widgets/side_nav_bar.dart';
import 'package:flutter_template/pages/home/widgets/shell_account_button.dart';
import 'package:flutter_template/pages/home/shell_login_page.dart';
import 'package:flutter_template/pages/home/shell_profile_page.dart';
import 'package:flutter_template/pages/page6/page6_settings_page.dart';

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
  bool _inspectorDrawerOpen = false;
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
    final byId = {for (final destination in _config.destinations) destination.id: destination};
    final ordered = <ShellDestination>[];
    for (final id in _settingsController.settings.navBarItemOrder) {
      final destination = byId[id];
      if (destination != null && !destination.isUtility && !ordered.contains(destination)) ordered.add(destination);
    }
    for (final destination in _config.destinations) {
      if (!destination.isUtility && !ordered.contains(destination)) ordered.add(destination);
    }
    final hidden = _settingsController.settings.hiddenNavBarItems.toSet();
    ordered.removeWhere((destination) => !destination.lockedVisible && hidden.contains(destination.id));
    return [...ordered, ..._config.destinations.where((destination) => destination.isUtility)];
  }

  ShellContext? get _selectedContext =>
      _config.contexts.where((context) => context.id == _selectedContextId).firstOrNull;

  List<ShellModule> get _modules => _selectedContext?.modules ?? _config.modules;
  ShellStatusProvider? get _activeStatusProvider => _activeTab == null ? null : _statusProviders[_activeTab!.id];
  ShellDestination? get _activeSection => _navigation.sectionFor(selectedActivityId);
  ShellViewBuilder? get _activeSplitBuilder {
    final builder = _activeTab == null ? null : _viewFor(_activeTab!.registrationId)?.splitPaneBuilder;
    if (builder != null) return builder;
    final globalBuilder = _config.splitPaneBuilder;
    return globalBuilder == null ? null : (context, _) => globalBuilder(context);
  }

  bool get _inspectorOpen =>
      _activeTab?.inspectorOpen ??
      _navigation.activeWorkspace.inspectorOpen ??
      _settingsController.settings.inspectorOpen;
  bool get _splitOpen => _activeTab?.splitOpen ?? _settingsController.settings.splitOpen;

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
      final activeSettingsTab = settingsTabs.where((tab) => tab.id == settings.selectedShellTabId).firstOrNull;
      final tab = activeSettingsTab ?? settingsTabs.first;
      workspaces['settings'] = ShellWorkspacePreference(sectionId: 'settings', tabs: [tab], activeTabId: tab.id);
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
    final sections = _config.destinations;
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
    final runtime = _ShellTabRuntime(isRestored: _restoringSettings, initialNavigationPath: tab.navigationPath);
    runtime.breadcrumbs.addListener(() => _handleBreadcrumbChanged(tab, runtime.breadcrumbs));
    return runtime;
  });

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
      runtime.dispose();
    }
    for (final tab in _allTabs) {
      _runtimeFor(tab);
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
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    final supplied = widget.config ?? defaultShellConfig();
    final views = [...supplied.views];
    final settingsRegistration = views.where((view) => view.id == 'settings').firstOrNull;
    views.removeWhere((view) => view.id == 'settings');
    views.add(
      ShellViewRegistration(
        id: 'settings',
        title: settingsRegistration?.title ?? (buildContext, _) => buildContext.l10n.settingsTitle,
        viewBuilder: settingsRegistration?.viewBuilder ?? (buildContext, _) => _buildSettingsView(buildContext),
        destinationId: 'settings',
        icon: settingsRegistration?.icon ?? Icons.settings_outlined,
        routePath: settingsRegistration?.routePath,
        reusePolicy: ShellViewReusePolicy.byRegistration,
        closeable: false,
      ),
    );
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
    final destinations = supplied.destinations.where((destination) => destination.id != 'settings').toList();
    final suppliedSettings = supplied.destinations.where((destination) => destination.id == 'settings').firstOrNull;
    destinations.add(
      ShellDestination(
        id: 'settings',
        title: suppliedSettings?.title ?? (buildContext) => buildContext.l10n.settingsTitle,
        icon: suppliedSettings?.icon ?? Icons.settings_outlined,
        inactiveIcon: suppliedSettings?.inactiveIcon ?? Icons.settings_outlined,
        lockedVisible: true,
        isUtility: true,
        defaultViewId: 'settings',
        allowedViewIds: const {'settings'},
        panelBuilder: suppliedSettings?.panelBuilder,
        inspectorBuilder: suppliedSettings?.inspectorBuilder,
        statusItemsBuilder: suppliedSettings?.statusItemsBuilder,
        statusProvider: suppliedSettings?.statusProvider,
        onSelected: suppliedSettings?.onSelected,
      ),
    );
    _config = ShellConfig(
      title: supplied.title,
      destinations: destinations,
      views: views,
      modules: supplied.modules,
      contexts: supplied.contexts,
      commands: supplied.commands,
      globalStatusProviders: supplied.globalStatusProviders,
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
      const Expanded(child: Page6SettingsPage()),
    ],
  );

  void _returnToPreviousSection() {
    final fallback = _config.destinations.where((destination) => !destination.isUtility).firstOrNull?.id;
    unawaited(selectedPage(_returnSectionId ?? fallback ?? 'settings'));
  }

  void _openLogin() {
    unawaited(
      Navigator.of(
        context,
        rootNavigator: true,
      ).push<void>(MaterialPageRoute(builder: (_) => ShellLoginPage(appTitle: _config.title(context)))),
    );
  }

  void _openProfile() {
    unawaited(
      Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute(
          builder: (_) => ShellProfilePage(appTitle: _config.title(context), onSignIn: _openLogin),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    final provider = AppScope.of(context).services.authProvider;
    if (provider == null) return;
    try {
      await provider.signOut();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.signOutFailed)));
    }
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

  void _toggleInspector() {
    _setInspectorOpen(!_inspectorOpen);
  }

  void _setInspectorOpen(bool isOpen) {
    final tab = _activeTab;
    if (tab?.inspectorOpen != null) {
      _navigation.updateTab(tab!.copyWith(inspectorOpen: isOpen));
      return;
    }
    final workspace = _navigation.activeWorkspace;
    if (workspace.inspectorOpen != null) {
      _navigation.setSectionInspectorOpen(selectedActivityId, isOpen: isOpen);
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
      _navigation.updateTab(tab.copyWith(splitOpen: !_splitOpen));
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
    if (active == null || builder == null) return const [];
    try {
      return builder(context, _viewContextFor(active));
    } catch (_) {
      return const [];
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

  List<_ShellCommand> _commands() {
    final commands = <_ShellCommand>[
      if (_config.destinations.any((item) => item.id == 'settings' || item.id == 'page6'))
        _ShellCommand(id: 'settings', title: context.l10n.openSettings, shortcut: '', run: _openSettings),
      _ShellCommand(
        id: 'inspector',
        title: _inspectorOpen ? context.l10n.closeInspector : context.l10n.openInspector,
        shortcut: '',
        run: _openInspector,
      ),
      if (_activeSplitBuilder != null)
        _ShellCommand(
          id: 'split',
          title: _splitOpen ? context.l10n.closeSplitView : context.l10n.openSplitView,
          shortcut: '',
          run: _toggleSplit,
        ),
      _ShellCommand(
        id: 'notifications',
        title: context.l10n.openNotifications,
        shortcut: '',
        run: _showNotificationsPanel,
      ),
      _ShellCommand(id: 'layout', title: context.l10n.restoreLayout, shortcut: '', run: _restoreLayout),
      _ShellCommand(id: 'theme', title: context.l10n.toggleAppearance, shortcut: '', run: _toggleAppearance),
      _ShellCommand(id: 'new-tab', title: context.l10n.openViewTab, shortcut: '', run: _showViewPicker),
      for (final command in _config.commands)
        _ShellCommand(
          id: command.id,
          title: command.title(context),
          shortcut: '',
          run: () async => command.run(context),
        ),
    ];
    for (final view in _navigation.viewsForSection(selectedActivityId)) {
      commands.add(
        _ShellCommand(
          id: 'open-view-${view.id}',
          title: context.l10n.openView(view.title(context, view.id)),
          shortcut: '',
          run: () => _navigation.openTab(selectedActivityId, view.id),
        ),
      );
    }
    for (final tab in _tabs) {
      commands.add(
        _ShellCommand(
          id: 'tab-${tab.id}',
          title: '${context.l10n.switchView}: ${_tabTitle(tab)}',
          shortcut: '',
          run: () => _navigation.selectTab(selectedActivityId, tab.id),
        ),
      );
    }
    for (final destination in _destinations) {
      commands.add(
        _ShellCommand(
          id: 'navigate-${destination.id}',
          title: context.l10n.navigateTo(destination.title(context)),
          shortcut: '',
          run: () => selectedPage(destination.id),
        ),
      );
    }
    for (final configured in _config.contexts) {
      commands.add(
        _ShellCommand(
          id: 'context-${configured.id}',
          title: context.l10n.switchContext(configured.title(context)),
          shortcut: '',
          run: () => _selectContext(configured.id),
        ),
      );
    }
    for (final module in _modules) {
      commands.add(
        _ShellCommand(
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
      builder: (_) => _CommandPaletteDialog(commands: _commands()),
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
      builder: (_) => _ViewPickerDialog(views: views, title: _viewTitle),
    );
    if (selected != null) _navigation.openTab(selectedActivityId, selected.id);
  }

  String _viewTitle(ShellViewRegistration registration) {
    return registration.title(context, registration.id);
  }

  Future<void> _maybePopCurrentPage() async {
    final navigator = _activeTab == null ? null : _tabRuntimes[_activeTab!.id]?.navigatorKey.currentState;
    await (navigator ?? widget.mainNavigatorKey.currentState)?.maybePop();
  }

  void _openInspector() {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 1200) {
      if (_inspectorDrawerOpen) {
        _setInspectorOpen(false);
        _scaffoldKey.currentState?.closeEndDrawer();
      } else {
        _setInspectorOpen(true);
        _scaffoldKey.currentState?.openEndDrawer();
      }
    } else {
      _toggleInspector();
    }
  }

  Widget _buildHeader(double width, AppShellMetrics metrics) {
    final theme = Theme.of(context);
    final actionSize = _isPhoneLayout
        ? metrics.targetSize
        : (Theme.of(context).extension<AppShellTokens>()?.comfortable == true ? 36.0 : 32.0);
    final actionIconSize = _isPhoneLayout ? 24.0 : 18.0;
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
              child: Text(
                _activeTab == null
                    ? (_destinations.where((item) => item.id == selectedActivityId).firstOrNull?.title(context) ??
                          _config.title(context))
                    : _tabTitle(_activeTab!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge,
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
            if (!_isPhoneLayout)
              if (_activeSection?.panelBuilder != null)
                headerAction(
                  'activity-panel',
                  IconButton(
                    tooltip: _activityPanelOpen ? context.l10n.closeSectionPanel : context.l10n.openSectionPanel,
                    onPressed: _toggleActivityPanel,
                    icon: const Icon(Icons.menu_open),
                  ),
                ),
            if (!_isPhoneLayout)
              headerAction(
                'inspector',
                IconButton(
                  tooltip: _inspectorOpen ? context.l10n.closeInspector : context.l10n.openInspector,
                  onPressed: _openInspector,
                  icon: Icon(_inspectorOpen ? Icons.vertical_split : Icons.vertical_split_outlined),
                ),
              ),
            if (_isPhoneLayout)
              headerAction('notifications', ShellNotificationsAction(service: notificationService, phone: true)),
            headerAction(
              'search',
              IconButton(
                tooltip: '${context.l10n.commandPalette} ($shortcut)',
                onPressed: _showCommandPalette,
                icon: const Icon(Icons.search),
              ),
            ),
            headerAction(
              'more',
              PopupMenuButton<String>(
                tooltip: context.l10n.moreActions,
                padding: EdgeInsets.zero,
                iconSize: actionIconSize,
                onSelected: (value) {
                  if (value == 'theme') _toggleAppearance();
                  if (value == 'layout') _restoreLayout();
                  if (value == 'split') _toggleSplit();
                  if (value == 'inspector') _openInspector();
                  if (value == 'tab') unawaited(_showViewPicker());
                },
                itemBuilder: (context) => [
                  if (_isPhoneLayout)
                    PopupMenuItem(
                      height: metrics.menuRowHeight,
                      value: 'inspector',
                      child: Text(_inspectorOpen ? context.l10n.closeInspector : context.l10n.openInspector),
                    ),
                  PopupMenuItem(height: metrics.menuRowHeight, value: 'tab', child: Text(context.l10n.openViewTab)),
                  PopupMenuItem(
                    height: metrics.menuRowHeight,
                    value: 'theme',
                    child: Text(context.l10n.toggleAppearance),
                  ),
                  if (_activeSplitBuilder != null)
                    PopupMenuItem(
                      height: metrics.menuRowHeight,
                      value: 'split',
                      child: Text(_splitOpen ? context.l10n.closeSplitView : context.l10n.openSplitView),
                    ),
                  PopupMenuItem(
                    height: metrics.menuRowHeight,
                    value: 'layout',
                    child: Text(context.l10n.restoreLayout),
                  ),
                ],
              ),
            ),
            headerAction(
              'account',
              ShellAccountButton(
                provider: AppScope.of(context).services.authProvider,
                onSignIn: _openLogin,
                onProfile: _openProfile,
                onSignOut: () => unawaited(_signOut()),
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
                  key: ValueKey(tab.id),
                  index: index,
                  child: _DesktopTab(
                    key: _tabKeys.putIfAbsent(tab.id, GlobalKey.new),
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
            tooltip: context.l10n.openViewTab,
            onPressed: _showViewPicker,
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
    final controller = TextEditingController(text: _tabTitle(tab));
    try {
      final title = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.renameTab),
          content: TextField(
            autofocus: true,
            controller: controller,
            decoration: InputDecoration(labelText: context.l10n.tabTitleLabel),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(context.l10n.save),
            ),
          ],
        ),
      );
      if (title != null && title.isNotEmpty && mounted) _navigation.updateTab(tab.copyWith(title: title));
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showTabOverflow() async {
    final id = await showDialog<String>(
      context: context,
      builder: (_) => _TabOverflowDialog(tabs: _tabs, title: _tabTitle),
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

  Widget _buildInspector({required bool drawer}) {
    final content = Builder(
      builder: (context) {
        try {
          final active = _activeTab;
          final tabBuilder = active == null ? null : _viewFor(active.registrationId)?.inspectorBuilder;
          if (active != null && tabBuilder != null) return tabBuilder(context, _viewContextFor(active));
          final sectionBuilder = _activeSection?.inspectorBuilder;
          if (sectionBuilder != null) return sectionBuilder(context);
          final globalBuilder = _config.inspectorBuilder;
          if (globalBuilder != null) return globalBuilder(context);
          return _defaultInspectorContent();
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
                Expanded(child: Text(context.l10n.inspector, style: Theme.of(context).textTheme.titleSmall)),
                IconButton(
                  tooltip: context.l10n.closeInspector,
                  onPressed: () {
                    _setInspectorOpen(false);
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

  Widget _defaultInspectorContent() {
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

  Widget _resizeHandle(double width) {
    void adjust(double delta) {
      final next = (width - delta).clamp(256.0, 440.0);
      _settingsController.update(_settingsController.settings.copyWith(inspectorWidth: next));
    }

    return Semantics(
      button: true,
      label: context.l10n.resizeInspector,
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
        final breadcrumbs = <ShellNavigationNode>[
          ShellNavigationNode(
            id: sectionNodeId,
            label: section?.title(context) ?? _config.title(context),
            icon: section?.icon,
            onActivate: section == null ? null : () => _navigation.selectSection(section.id),
            childrenProvider: _destinations.length > 1
                ? () async => [
                    for (final destination in _destinations)
                      ShellNavigationNode(
                        id: 'shell-section:${destination.id}',
                        label: destination.title(context),
                        icon: destination.icon,
                        onActivate: () => _navigation.selectSection(destination.id),
                      ),
                  ]
                : null,
          ),
        ];
        if (activeTab case final tab?) {
          breadcrumbs.add(
            ShellNavigationNode(
              id: 'shell-tab:${tab.id}',
              label: _tabTitle(tab),
              icon: _tabIcon(tab),
              parentId: sectionNodeId,
              onActivate: () => _navigation.selectTab(tab.sectionId ?? sectionId, tab.id),
              childrenProvider: _tabs.length > 1
                  ? () async => [
                      for (final sibling in _tabs)
                        ShellNavigationNode(
                          id: 'shell-tab:${sibling.id}',
                          label: _tabTitle(sibling),
                          icon: _tabIcon(sibling),
                          parentId: sectionNodeId,
                          onActivate: () => _navigation.selectTab(sibling.sectionId ?? sectionId, sibling.id),
                        ),
                    ]
                  : null,
            ),
          );
          if (controller != null) {
            for (final node in controller.activePath) {
              breadcrumbs.add(
                ShellNavigationNode(
                  id: node.id,
                  label: node.label,
                  icon: node.icon,
                  parentId: node.parentId,
                  onActivate: () => controller.navigateTo(node.id),
                  children: node.children,
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

        final tabItems = [...?_activeStatusProvider?.items].where((item) => item.isVisible?.call() ?? true).toList();
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
    final shellTheme = _isPhoneLayout
        ? baseTheme.copyWith(
            textTheme: baseTheme.textTheme.copyWith(
              bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(fontSize: 16),
              labelSmall: baseTheme.textTheme.labelSmall?.copyWith(fontSize: 14),
              labelMedium: baseTheme.textTheme.labelMedium?.copyWith(fontSize: 15),
            ),
          )
        : baseTheme;
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
        final wide = width >= 1200;
        final visible = _destinations;
        final settings = _settingsController.settings;
        final metrics = AppTheme.metrics(context, phone: _isPhoneLayout);
        final showInspector = wide && _inspectorOpen;
        final availableInspectorWidth = (width - metrics.railWidth - 400).clamp(256.0, 440.0);
        final inspectorWidth = settings.inspectorWidth.clamp(256.0, availableInspectorWidth);
        final body = _activeContent();
        final activeActivity = _destinations.where((item) => item.id == selectedActivityId).firstOrNull;
        final showActivityPanel =
            !_isPhoneLayout && width >= 800 && _activityPanelOpen && activeActivity?.panelBuilder != null;

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
                      endDrawer: Drawer(child: _buildInspector(drawer: true)),
                      onEndDrawerChanged: (isOpen) {
                        _inspectorDrawerOpen = isOpen;
                        if (!isOpen && _inspectorOpen) _setInspectorOpen(false);
                      },
                      body: SafeArea(
                        bottom: false,
                        child: Column(
                          children: [
                            _buildHeader(width, metrics),
                            if (!_isPhoneLayout) _buildTabStrip(metrics),
                            Expanded(
                              child: Row(
                                children: [
                                  if (!_isPhoneLayout)
                                    SideNavBar(
                                      currentId: currentDestinationId,
                                      destinations: visible,
                                      onSelected: (id) => unawaited(selectedPage(id)),
                                    ),
                                  if (showActivityPanel) _buildActivityPanel(activeActivity!),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.all(wide ? 8 : 0),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) =>
                                            _buildSplit(body, constraints.maxWidth - (wide ? 16 : 0), wide: wide),
                                      ),
                                    ),
                                  ),
                                  if (showInspector) ...[
                                    _resizeHandle(inspectorWidth),
                                    SizedBox(width: inspectorWidth, child: _buildInspector(drawer: false)),
                                  ],
                                ],
                              ),
                            ),
                            if (!_isPhoneLayout) _buildStatusBar(metrics),
                          ],
                        ),
                      ),
                      bottomNavigationBar: _isPhoneLayout
                          ? SafeArea(
                              top: false,
                              child: BottomNavBar(
                                currentId: currentDestinationId,
                                destinations: visible,
                                onSelected: (id) => unawaited(selectedPage(id)),
                              ),
                            )
                          : null,
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
  _ShellTabRuntime({required this.isRestored, required List<String> initialNavigationPath})
    : lifecycle = ValueNotifier(isRestored ? ShellTabLifecycle.restored : ShellTabLifecycle.opened),
      breadcrumbs = ShellBreadcrumbController(initialPath: initialNavigationPath);

  final bool isRestored;
  final ValueNotifier<ShellTabLifecycle> lifecycle;
  final ShellBreadcrumbController breadcrumbs;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<AnimatedEntryState> entryAnimationKey = GlobalKey<AnimatedEntryState>();
  final GlobalKey<AnimatedExitState> exitAnimationKey = GlobalKey<AnimatedExitState>();

  ShellViewContext viewContext(ShellTabPreference tab, GlobalKey<NavigatorState> mainNavigatorKey) => ShellViewContext(
    tab: tab,
    isRestored: isRestored,
    lifecycle: lifecycle,
    breadcrumbs: breadcrumbs,
    mainNavigatorKey: mainNavigatorKey,
    entryAnimationKey: entryAnimationKey,
    exitAnimationKey: exitAnimationKey,
  );

  void dispose() {
    lifecycle.dispose();
    breadcrumbs.dispose();
  }
}

class _ShellCommand {
  final String id;
  final String title;
  final String shortcut;
  final FutureOr<void> Function() run;

  const _ShellCommand({required this.id, required this.title, required this.shortcut, required this.run});
}

class _CommandPaletteDialog extends StatefulWidget {
  final List<_ShellCommand> commands;

  const _CommandPaletteDialog({required this.commands});

  @override
  State<_CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<_CommandPaletteDialog> {
  final TextEditingController _controller = TextEditingController();
  int _selectedIndex = 0;

  List<_ShellCommand> get _filtered =>
      widget.commands.where((command) => command.title.toLowerCase().contains(_controller.text.toLowerCase())).toList();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSelected(int index) {
    final filtered = _filtered;
    if (index < 0 || index >= filtered.length) return;
    final command = filtered[index];
    Navigator.of(context).pop();
    unawaited(Future<void>.sync(command.run));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    _selectedIndex = filtered.isEmpty ? 0 : _selectedIndex.clamp(0, filtered.length - 1);
    final listHeight = (MediaQuery.sizeOf(context).height - 128).clamp(160.0, 400.0);

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: (MediaQuery.sizeOf(context).height - 32).clamp(240.0, 560.0),
        ),
        child: Focus(
          autofocus: true,
          onKeyEvent: (_, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            if (event.logicalKey == LogicalKeyboardKey.arrowDown && filtered.isNotEmpty) {
              setState(() => _selectedIndex = (_selectedIndex + 1) % filtered.length);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowUp && filtered.isNotEmpty) {
              setState(() => _selectedIndex = (_selectedIndex - 1 + filtered.length) % filtered.length);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.enter && filtered.isNotEmpty) {
              _runSelected(_selectedIndex);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).pop();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: context.l10n.commandPaletteHint,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() => _selectedIndex = 0),
                  onSubmitted: (_) => _runSelected(_selectedIndex),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: listHeight,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => ListTile(
                      key: ValueKey(filtered[index].id),
                      selected: _selectedIndex == index,
                      leading: const Icon(Icons.arrow_forward),
                      title: Text(filtered[index].title),
                      trailing: filtered[index].shortcut.isEmpty ? null : Text(filtered[index].shortcut),
                      onTap: () => _runSelected(index),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopTab extends StatefulWidget {
  final String title;
  final IconData? icon;
  final bool selected;
  final bool closable;
  final VoidCallback onSelect;
  final VoidCallback onClose;
  final ValueChanged<Offset> onContextMenu;

  const _DesktopTab({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.closable,
    required this.onSelect,
    required this.onClose,
    required this.onContextMenu,
  });

  @override
  State<_DesktopTab> createState() => _DesktopTabState();
}

class _DesktopTabState extends State<_DesktopTab> {
  bool _hovered = false;
  bool _focused = false;

  void _showContextMenu() {
    final box = context.findRenderObject() as RenderBox?;
    widget.onContextMenu(box?.localToGlobal(Offset(0, box.size.height)) ?? Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showClose = widget.closable && (widget.selected || _hovered || _focused);
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.title,
      child: Tooltip(
        message: widget.title,
        child: Focus(
          onFocusChange: (value) => setState(() => _focused = value),
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.contextMenu ||
                    (event.logicalKey == LogicalKeyboardKey.f10 && HardwareKeyboard.instance.isShiftPressed))) {
              _showContextMenu();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: Listener(
              onPointerDown: (event) {
                if (event.kind == PointerDeviceKind.mouse &&
                    event.buttons & kMiddleMouseButton != 0 &&
                    widget.closable) {
                  widget.onClose();
                }
              },
              child: GestureDetector(
                onSecondaryTapDown: (details) => widget.onContextMenu(details.globalPosition),
                child: Material(
                  color: widget.selected
                      ? theme.colorScheme.surface
                      : _hovered
                      ? theme.colorScheme.surfaceContainerHighest
                      : Colors.transparent,
                  child: InkWell(
                    onTap: widget.onSelect,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 88, maxWidth: 190),
                      height: 34,
                      padding: const EdgeInsets.only(left: 9, right: 4),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: widget.selected ? theme.colorScheme.primary : Colors.transparent,
                            width: 2,
                          ),
                          right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: widget.selected
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (showClose)
                            IconButton(
                              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                              onPressed: widget.onClose,
                              icon: const Icon(Icons.close, size: 14),
                              style: IconButton.styleFrom(
                                minimumSize: const Size.square(26),
                                maximumSize: const Size.square(26),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewPickerDialog extends StatefulWidget {
  final List<ShellViewRegistration> views;
  final String Function(ShellViewRegistration) title;

  const _ViewPickerDialog({required this.views, required this.title});

  @override
  State<_ViewPickerDialog> createState() => _ViewPickerDialogState();
}

class _ViewPickerDialogState extends State<_ViewPickerDialog> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.views
        .where((view) => widget.title(view).toLowerCase().contains(_search.text.toLowerCase()))
        .toList();
    return AlertDialog(
      title: Text(context.l10n.viewPickerTitle),
      content: SizedBox(
        width: 420,
        height: 360,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              controller: _search,
              decoration: InputDecoration(hintText: context.l10n.viewPickerHint, prefixIcon: const Icon(Icons.search)),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final view = results[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(view.icon ?? Icons.insert_drive_file_outlined),
                    title: Text(widget.title(view)),
                    onTap: () => Navigator.of(context).pop(view),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabOverflowDialog extends StatefulWidget {
  final List<ShellTabPreference> tabs;
  final String Function(ShellTabPreference) title;

  const _TabOverflowDialog({required this.tabs, required this.title});

  @override
  State<_TabOverflowDialog> createState() => _TabOverflowDialogState();
}

class _TabOverflowDialogState extends State<_TabOverflowDialog> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.tabs
        .where((tab) => widget.title(tab).toLowerCase().contains(_search.text.toLowerCase()))
        .toList();
    return AlertDialog(
      title: Text(context.l10n.tabOverflowTitle),
      content: SizedBox(
        width: 420,
        height: 360,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              controller: _search,
              decoration: InputDecoration(hintText: context.l10n.searchLabel, prefixIcon: const Icon(Icons.search)),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) => ListTile(
                  dense: true,
                  title: Text(widget.title(results[index])),
                  onTap: () => Navigator.of(context).pop(results[index].id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
