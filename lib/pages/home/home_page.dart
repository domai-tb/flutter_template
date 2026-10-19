import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
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
import 'package:flutter_template/pages/home/widgets/side_nav_bar.dart';
import 'package:flutter_template/pages/page6/page6_settings_page.dart';

class HomePage extends StatefulWidget {
  final GlobalKey<NavigatorState> mainNavigatorKey;
  final ShellConfig? config;

  const HomePage({super.key, required this.mainNavigatorKey, this.config});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final PageController pageController = PageController();
  final ScrollController _tabScrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<String, GlobalKey<NavigatorState>> navigatorKeys = {};
  final Map<String, GlobalKey<AnimatedExitState>> exitAnimationKeys = {};
  final Map<String, GlobalKey<AnimatedEntryState>> entryAnimationKeys = {};
  final Map<String, GlobalKey> _tabKeys = {};
  final Map<String, ShellStatusProvider> _statusProviders = {};

  late final ShellConfig _config;
  late final ShellNavigationCoordinator _navigation;
  late SettingsController _settingsController;
  double _splitRatio = 0.5;
  double pagePosition = 0;
  bool swipeDisabled = false;
  bool _settingsWired = false;
  bool _handlingPlatformRoute = false;
  bool _phonePageSyncScheduled = false;
  bool _restoringSettings = false;
  String? _lastPushedRouteId;

  bool get _isPhoneLayout =>
      defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  List<ShellTabPreference> get _tabs => _navigation.tabs;
  String? get _selectedTabId => _navigation.activeId;
  ShellTabPreference? get _activeTab => _navigation.activeTab;
  String get currentDestinationId =>
      _activeTab?.destinationId ??
      _viewFor(_activeTab?.registrationId ?? '')?.destinationId ??
      _destinations.firstOrNull?.id ??
      '';
  String? get _selectedContextId => _activeTab?.contextId ?? _settingsController.settings.selectedContextId;
  PageItem get currentPage => pageItemFromId(currentDestinationId) ?? PageItem.page1;

  List<ShellDestination> get _destinations {
    final byId = {for (final destination in _config.destinations) destination.id: destination};
    final ordered = <ShellDestination>[];
    for (final id in _settingsController.settings.navBarItemOrder) {
      final destination = byId[id];
      if (destination != null && !ordered.contains(destination)) ordered.add(destination);
    }
    for (final destination in _config.destinations) {
      if (!ordered.contains(destination)) ordered.add(destination);
    }
    final hidden = _settingsController.settings.hiddenNavBarItems.toSet();
    return ordered
        .where(
          (destination) =>
              destination.lockedVisible || destination.id == 'settings' || !hidden.contains(destination.id),
        )
        .toList();
  }

  List<ShellDestination> get _allDestinations => _config.destinations;

  ShellContext? get _selectedContext =>
      _config.contexts.where((context) => context.id == _selectedContextId).firstOrNull;

  List<ShellModule> get _modules => _selectedContext?.modules ?? _config.modules;
  ShellStatusProvider? get _activeStatusProvider => _activeTab == null ? null : _statusProviders[_activeTab!.id];
  WidgetBuilder? get _activeInspectorBuilder =>
      (_activeTab == null ? null : _viewFor(_activeTab!.registrationId)?.inspectorBuilder) ?? _config.inspectorBuilder;
  WidgetBuilder? get _activeSplitBuilder =>
      (_activeTab == null ? null : _viewFor(_activeTab!.registrationId)?.splitPaneBuilder) ?? _config.splitPaneBuilder;
  bool get _inspectorOpen => _activeTab?.inspectorOpen ?? _settingsController.settings.inspectorOpen;
  bool get _splitOpen => _activeTab?.splitOpen ?? _settingsController.settings.splitOpen;

  List<ShellTabPreference> _validTabs(Settings settings, {required String defaultDestinationId}) {
    final registrations = {for (final view in _config.views) view.id: view};
    final seen = <String>{};
    final seenRoots = <String>{};
    final result = <ShellTabPreference>[];
    final fallbackRoot = _rootRegistrationFor(defaultDestinationId);
    for (final tab in settings.shellTabs) {
      if (tab.registrationId == 'placeholder' && tab.id.startsWith('placeholder-')) continue;
      final legacyRoute = tab.id == 'route' || tab.registrationId == 'route';
      final registration = legacyRoute ? _rootRegistrationFor(defaultDestinationId) : registrations[tab.registrationId];
      if (legacyRoute) {
        if (registration != null && seenRoots.add(registration.id)) {
          result.add(
            ShellTabPreference(
              id: registration.id,
              registrationId: registration.id,
              destinationId: defaultDestinationId,
              contextId: settings.selectedContextId,
            ),
          );
        }
        final moduleView = settings.selectedModuleId == null
            ? null
            : _moduleView(settings.selectedContextId, settings.selectedModuleId!);
        if (moduleView != null && !result.any((item) => item.registrationId == moduleView.id)) {
          result.add(
            ShellTabPreference(
              id: '${moduleView.id}-1',
              registrationId: moduleView.id,
              destinationId: defaultDestinationId,
              contextId: settings.selectedContextId,
              moduleId: settings.selectedModuleId,
            ),
          );
        }
        continue;
      }
      if (!seen.add(tab.id)) continue;
      if (registration?.isRoot == true) {
        final destinationId = registration!.destinationId!;
        if (!seenRoots.add(destinationId)) continue;
        result.add(
          ShellTabPreference(
            id: registration.id,
            registrationId: registration.id,
            destinationId: destinationId,
            contextId: tab.contextId,
            moduleId: tab.moduleId,
            inspectorOpen: tab.inspectorOpen,
            splitOpen: tab.splitOpen,
          ),
        );
      } else if (registration == null &&
          tab.id == 'page1' &&
          tab.registrationId == 'page1' &&
          defaultDestinationId != 'page1' &&
          fallbackRoot != null) {
        if (seenRoots.add(defaultDestinationId)) result.add(_rootPreference(defaultDestinationId));
      } else {
        result.add(tab);
      }
    }
    if (result.isEmpty && settings.shellTabs.isNotEmpty && fallbackRoot != null) {
      result.add(_rootPreference(defaultDestinationId));
    }
    return result;
  }

  ShellViewRegistration? _rootRegistrationFor(String destinationId) =>
      _config.views.where((view) => view.isRoot && view.destinationId == destinationId).firstOrNull;

  ShellTabPreference _rootPreference(String destinationId) {
    final registration = _rootRegistrationFor(destinationId);
    final contextId = _settingsController.settings.selectedContextId ?? _config.contexts.firstOrNull?.id;
    return ShellTabPreference(
      id: registration?.id ?? destinationId,
      registrationId: registration?.id ?? destinationId,
      destinationId: destinationId,
      contextId: contextId,
    );
  }

  String? _migratedRouteSelection(Settings settings, String destinationId) {
    final module = settings.selectedModuleId == null
        ? null
        : _moduleView(settings.selectedContextId, settings.selectedModuleId!);
    return module == null ? _rootRegistrationFor(destinationId)?.id : '${module.id}-1';
  }

  ShellViewRegistration? _viewFor(String registrationId) {
    for (final view in _config.views) {
      if (view.id == registrationId) return view;
    }
    return null;
  }

  void setSwipeDisabled({bool disableSwipe = false}) {
    setState(() => swipeDisabled = disableSwipe);
  }

  Future<bool> selectedPage(String id) async {
    final destinations = _destinations;
    if (!destinations.any((destination) => destination.id == id)) return false;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (_isPhoneLayout) {
      final index = destinations.indexWhere((destination) => destination.id == id);
      if (pageController.hasClients) {
        if (disableAnimations) {
          pageController.jumpToPage(index);
        } else {
          await pageController.animateToPage(index, duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
        }
      }
      if (!mounted) return false;
    }
    final active = _activeTab;
    final activeRegistration = active == null ? null : _viewFor(active.registrationId);
    if (activeRegistration?.isRoot != true || activeRegistration?.destinationId != id) {
      _navigation.open(_rootPreference(id), reuseRegistration: true);
    }
    _updateBrowserRoute(id);
    if (mounted) {
      final title = destinations.where((destination) => destination.id == id).firstOrNull?.title(context);
      if (title != null) _announce(title);
    }
    if (mounted) setState(() => swipeDisabled = false);
    return true;
  }

  void _updateBrowserRoute(String id) {
    if (!kIsWeb || _handlingPlatformRoute || _lastPushedRouteId == id) return;
    _lastPushedRouteId = id;
    unawaited(SystemNavigator.routeInformationUpdated(uri: Uri(pathSegments: [id])));
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async {
    final segments = routeInformation.uri.pathSegments;
    final id = segments.isEmpty ? _destinations.firstOrNull?.id : segments.last;
    if (id == null || !_destinations.any((destination) => destination.id == id)) return false;
    _lastPushedRouteId = id;
    _handlingPlatformRoute = true;
    try {
      await selectedPage(id);
    } finally {
      _handlingPlatformRoute = false;
    }
    return true;
  }

  Widget _navigatorFor(ShellDestination destination) {
    return NavBarNavigator(
      mainNavigatorKey: widget.mainNavigatorKey,
      navigatorKey: navigatorKeys[destination.id]!,
      destination: destination,
      pageEntryAnimationKey: entryAnimationKeys[destination.id]!,
      pageExitAnimationKey: exitAnimationKeys[destination.id]!,
    );
  }

  Widget _routeContent(List<ShellDestination> visible) {
    if (visible.isEmpty) return Center(child: Text(context.l10n.shellNoDestinations));

    if (_isPhoneLayout) {
      final activeIndex = visible.indexWhere((item) => item.id == currentDestinationId);
      if (activeIndex >= 0 &&
          !_phonePageSyncScheduled &&
          (!pageController.hasClients || (pageController.page?.round() ?? 0) != activeIndex)) {
        _phonePageSyncScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _phonePageSyncScheduled = false;
          if (mounted && pageController.hasClients && (pageController.page?.round() ?? 0) != activeIndex) {
            pageController.jumpToPage(activeIndex);
          }
        });
      }
      return PageView.builder(
        physics: swipeDisabled ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
        controller: pageController,
        itemCount: visible.length,
        onPageChanged: (index) {
          if (index < visible.length && visible[index].id != currentDestinationId) {
            _navigation.open(_rootPreference(visible[index].id), reuseRegistration: true);
            _updateBrowserRoute(visible[index].id);
          }
        },
        itemBuilder: (context, index) => AnimatedOpacity(
          opacity: (1 - (pagePosition - index).abs()).clamp(0, 1),
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 100),
          child: _navigatorFor(visible[index]),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: _allDestinations.map((destination) {
        return Offstage(
          offstage: destination.id != currentDestinationId,
          child: TickerMode(enabled: destination.id == currentDestinationId, child: _navigatorFor(destination)),
        );
      }).toList(),
    );
  }

  Widget _activeContent(List<ShellDestination> visible) {
    if (_tabs.isEmpty || _activeTab == null) {
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
    final active = _activeTab!;
    final registration = _viewFor(active.registrationId);
    final activeIsRoot = registration?.isRoot == true;
    final customTabs = _tabs.where((tab) => _viewFor(tab.registrationId)?.isRoot != true).toList();
    final customIndex = customTabs.isEmpty
        ? 0
        : customTabs.indexWhere((tab) => tab.id == active.id).clamp(0, customTabs.length - 1);
    final customContent = customTabs.isEmpty
        ? const SizedBox.shrink()
        : IndexedStack(index: customIndex, children: customTabs.map(_registeredViewContent).toList());
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(offstage: !activeIsRoot, child: _routeContent(visible)),
        Offstage(offstage: activeIsRoot, child: customContent),
      ],
    );
  }

  Widget _registeredViewContent(ShellTabPreference tab) {
    final registration = _viewFor(tab.registrationId);
    if (registration == null) return Center(child: Text(context.l10n.shellMissingView));
    if (registration.isRoot) return const SizedBox.shrink();
    if (registration.builder == null) return Center(child: Text(context.l10n.shellMissingView));
    try {
      return KeyedSubtree(key: ValueKey(tab.id), child: registration.builder!(context));
    } catch (error) {
      return Center(child: Text(context.l10n.shellContentError('$error')));
    }
  }

  void _openRegisteredView(ShellViewRegistration registration, {bool reuseRegistration = false}) =>
      _openView(registration, reuseRegistration: reuseRegistration);

  void _closeTab(ShellTabPreference tab) {
    _navigation.close(tab.id, closable: _viewFor(tab.registrationId)?.closeable ?? true);
  }

  void _reorderTabs(int oldIndex, int newIndex) => _navigation.reorder(oldIndex, newIndex);

  void _moveTab(ShellTabPreference tab, int offset) => _navigation.move(tab.id, offset);

  String _tabTitle(ShellTabPreference tab) {
    final registration = _viewFor(tab.registrationId);
    if (registration?.isRoot == true) {
      return _config.destinations
              .where((destination) => destination.id == registration!.destinationId)
              .firstOrNull
              ?.title(context) ??
          context.l10n.shellMissingView;
    }
    return registration?.title(context, tab.id) ?? context.l10n.shellMissingView;
  }

  IconData? _tabIcon(ShellTabPreference tab) {
    final registration = _viewFor(tab.registrationId);
    if (registration?.icon != null) return registration!.icon;
    return _config.destinations
        .where((destination) => destination.id == (registration?.destinationId ?? tab.destinationId))
        .firstOrNull
        ?.icon;
  }

  void _handleSettingsChanged() {
    if (!mounted || !_settingsWired) return;
    final visible = _destinations;
    final activeDestination = _activeTab?.destinationId;
    final defaultDestination = visible.any((item) => item.id == activeDestination)
        ? activeDestination!
        : visible.firstOrNull?.id ?? _config.destinations.firstOrNull?.id ?? '';
    final settings = _settingsController.settings;
    final valid = _validTabs(settings, defaultDestinationId: defaultDestination);
    final migratedId = settings.selectedShellTabId == 'route'
        ? _migratedRouteSelection(settings, defaultDestination)
        : null;
    final selectedId = migratedId != null && valid.any((tab) => tab.id == migratedId)
        ? migratedId
        : valid.any((tab) => tab.id == settings.selectedShellTabId)
        ? settings.selectedShellTabId
        : valid.firstOrNull?.id;
    _restoringSettings = true;
    _navigation.restore(valid, selectedId);
    _restoringSettings = false;
    setState(() {
      _splitRatio = settings.splitRatio;
    });
    _syncStatusProviders();
  }

  void _handleNavigationChanged() {
    _syncStatusProviders();
    if (!mounted || !_settingsWired || _restoringSettings) return;
    setState(() {});
    final active = _activeTab;
    final settings = _settingsController.settings;
    _settingsController.update(
      settings.copyWith(
        shellTabs: _tabs,
        selectedShellTabId: _selectedTabId ?? '',
        selectedContextId: active?.contextId ?? settings.selectedContextId,
        selectedModuleId: active == null ? settings.selectedModuleId : active.moduleId,
        inspectorOpen: active?.inspectorOpen ?? settings.inspectorOpen,
        splitOpen: active?.splitOpen ?? settings.splitOpen,
      ),
    );
    if (active?.destinationId case final destinationId?) _updateBrowserRoute(destinationId);
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
    final tabIds = _tabs.map((tab) => tab.id).toSet();
    for (final id in _statusProviders.keys.where((id) => !tabIds.contains(id)).toList()) {
      final provider = _statusProviders.remove(id)!;
      provider.removeListener(_handleStatusChanged);
      provider.dispose();
      _tabKeys.remove(id);
    }
    for (final tab in _tabs) {
      final factory = _viewFor(tab.registrationId)?.statusProviderFactory;
      if (factory != null && !_statusProviders.containsKey(tab.id)) {
        final provider = factory(tab.id);
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
    WidgetsBinding.instance.addObserver(this);
    final supplied = widget.config ?? defaultShellConfig();
    final legacyViewIds = {'route', 'placeholder'};
    final views = supplied.views.where((view) => !legacyViewIds.contains(view.id)).toList();
    for (final destination in supplied.destinations) {
      if (!views.any((view) => view.isRoot && view.destinationId == destination.id)) {
        views.add(
          ShellViewRegistration(
            id: destination.id,
            title: (buildContext, _) => destination.title(buildContext),
            destinationId: destination.id,
            icon: destination.icon,
            isRoot: true,
          ),
        );
      }
    }
    final page6 = supplied.destinations.where((destination) => destination.id == 'page6').firstOrNull;
    if (page6 != null && !views.any((view) => view.id == 'settings')) {
      views.add(
        ShellViewRegistration(
          id: 'settings',
          title: (buildContext, _) => buildContext.l10n.settingsTitle,
          builder: (_) => const Page6SettingsPage(),
          destinationId: page6.id,
          icon: Icons.settings_outlined,
        ),
      );
    }
    for (final context in supplied.contexts) {
      for (final module in context.modules) {
        views.add(
          ShellViewRegistration(
            id: 'module.${context.id}.${module.id}',
            title: (buildContext, _) => module.title(buildContext),
            builder: module.builder,
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
          builder: module.builder,
          moduleId: module.id,
        ),
      );
    }
    _config = ShellConfig(
      title: supplied.title,
      destinations: supplied.destinations,
      views: views,
      modules: supplied.modules,
      contexts: supplied.contexts,
      inspectorBuilder: supplied.inspectorBuilder,
      splitPaneBuilder: supplied.splitPaneBuilder,
    );
    _navigation = ShellNavigationCoordinator();
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
    final visible = _destinations;
    final initialRoute = kIsWeb ? Uri.base.pathSegments.lastOrNull : null;
    final defaultDestination = visible.any((destination) => destination.id == initialRoute)
        ? initialRoute!
        : visible.firstOrNull?.id ?? _config.destinations.firstOrNull?.id ?? '';
    final validTabs = _validTabs(settings, defaultDestinationId: defaultDestination);
    final routedRoot = visible.any((destination) => destination.id == initialRoute)
        ? _rootRegistrationFor(initialRoute!)?.id
        : null;
    final migratedId = settings.selectedShellTabId == 'route'
        ? _migratedRouteSelection(settings, defaultDestination)
        : null;
    final selectedId =
        routedRoot ??
        migratedId ??
        (validTabs.any((tab) => tab.id == settings.selectedShellTabId) ? settings.selectedShellTabId : null) ??
        validTabs.firstOrNull?.id;
    _restoringSettings = true;
    _navigation.restore(validTabs, selectedId);
    _restoringSettings = false;
    _lastPushedRouteId = _activeTab?.destinationId;
    _splitRatio = settings.splitRatio;
    _settingsWired = true;
    _syncStatusProviders();
    if (selectedId != null) _scrollTabIntoView(selectedId);
    if (validTabs.length != settings.shellTabs.length || selectedId != settings.selectedShellTabId) {
      final active = _activeTab;
      final migrated = settings.copyWith(
        shellTabs: validTabs,
        selectedShellTabId: selectedId ?? '',
        selectedContextId: active?.contextId,
        selectedModuleId: active?.moduleId,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _settingsController.update(migrated);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_settingsWired) _settingsController.removeListener(_handleSettingsChanged);
    _navigation.removeListener(_handleNavigationChanged);
    for (final provider in _statusProviders.values) {
      provider.removeListener(_handleStatusChanged);
      provider.dispose();
    }
    _statusProviders.clear();
    _navigation.dispose();
    pageController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  Future<void> _openSettings() async {
    final settingsView = _config.views.where((view) => view.id == 'settings' && !view.isRoot).firstOrNull;
    if (settingsView != null) {
      _openRegisteredView(settingsView, reuseRegistration: true);
      return;
    }
    final destination = _config.destinations.where((item) => item.id == 'settings' || item.id == 'page6').firstOrNull;
    if (destination != null) await selectedPage(destination.id);
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
    final settings = _settingsController.settings;
    final tab = _activeTab;
    if (tab == null) {
      _settingsController.update(settings.copyWith(inspectorOpen: !settings.inspectorOpen));
    } else {
      _navigation.updateActive(tab.copyWith(inspectorOpen: !_inspectorOpen));
    }
  }

  void _toggleSplit() {
    final settings = _settingsController.settings;
    final tab = _activeTab;
    if (tab == null) {
      _settingsController.update(settings.copyWith(splitOpen: !settings.splitOpen));
    } else {
      _navigation.updateActive(tab.copyWith(splitOpen: !_splitOpen));
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
    final module = selected.modules.firstOrNull;
    final registration = module == null ? null : _moduleView(selected.id, module.id);
    if (registration != null) {
      _openRegisteredView(registration, reuseRegistration: true);
    } else if (_activeTab case final active?) {
      _navigation.updateActive(active.copyWith(contextId: selected.id, moduleId: null));
    }
  }

  void _selectModule(String id) {
    if (!_modules.any((module) => module.id == id)) return;
    final registration = _moduleView(_selectedContextId, id);
    if (registration != null) _openRegisteredView(registration, reuseRegistration: true);
  }

  ShellViewRegistration? _moduleView(String? contextId, String moduleId) =>
      _config.views.where((view) => view.contextId == contextId && view.moduleId == moduleId).firstOrNull;

  void _openView(ShellViewRegistration registration, {bool reuseRegistration = false}) {
    if (registration.isRoot && registration.destinationId != null) {
      _navigation.open(_rootPreference(registration.destinationId!), reuseRegistration: true);
      return;
    }
    var index = 1;
    while (_tabs.any((tab) => tab.id == '${registration.id}-$index')) {
      index++;
    }
    _navigation.open(
      ShellTabPreference(
        id: '${registration.id}-$index',
        registrationId: registration.id,
        destinationId: registration.destinationId ?? currentDestinationId,
        contextId: registration.contextId ?? _selectedContextId,
        moduleId: registration.moduleId,
      ),
      reuseRegistration: reuseRegistration,
    );
  }

  void _restoreLayout() {
    final settings = _settingsController.settings;
    final defaultContext = _config.contexts.firstOrNull;
    final destination = _config.destinations.firstOrNull;
    final tabs = destination == null
        ? const <ShellTabPreference>[]
        : [
            ShellTabPreference(
              id: destination.id,
              registrationId: _rootRegistrationFor(destination.id)?.id ?? destination.id,
              destinationId: destination.id,
              contextId: defaultContext?.id,
              inspectorOpen: false,
              splitOpen: false,
            ),
          ];
    _settingsController.update(
      settings.copyWith(
        inspectorOpen: false,
        inspectorWidth: 320,
        splitOpen: false,
        splitRatio: 0.5,
        shellTabs: tabs,
        selectedShellTabId: tabs.firstOrNull?.id ?? '',
        selectedContextId: defaultContext?.id,
        selectedModuleId: null,
      ),
    );
    _announce(context.l10n.restoreLayout);
  }

  List<_ShellCommand> _commands() {
    final commands = <_ShellCommand>[
      if (_config.destinations.any((item) => item.id == 'settings' || item.id == 'page6'))
        _ShellCommand(id: 'settings', title: context.l10n.openSettings, shortcut: '', run: _openSettings),
      if (_activeInspectorBuilder != null)
        _ShellCommand(
          id: 'inspector',
          title: _inspectorOpen ? context.l10n.closeInspector : context.l10n.openInspector,
          shortcut: '',
          run: _toggleInspector,
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
    ];
    for (final view in _config.views.where((view) => !view.isRoot)) {
      commands.add(
        _ShellCommand(
          id: 'open-view-${view.id}',
          title: context.l10n.openView(view.title(context, view.id)),
          shortcut: '',
          run: () => _openRegisteredView(view),
        ),
      );
    }
    for (final tab in _tabs) {
      commands.add(
        _ShellCommand(
          id: 'tab-${tab.id}',
          title: '${context.l10n.switchView}: ${_tabTitle(tab)}',
          shortcut: '',
          run: () => _navigation.select(tab.id),
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
    if (index >= 0 && index < _tabs.length) _navigation.select(_tabs[index].id);
  }

  void _selectRelativeTab(int offset) {
    if (_tabs.isEmpty) return;
    final index = _tabs.indexWhere((tab) => tab.id == _selectedTabId);
    _selectTabIndex((index + offset + _tabs.length) % _tabs.length);
  }

  void _closeActiveTab() {
    final tab = _activeTab;
    if (tab != null) _closeTab(tab);
  }

  Future<void> _showViewPicker() async {
    final views = _config.views.where((view) => view.isRoot || view.builder != null).toList();
    final selected = await showDialog<ShellViewRegistration>(
      context: context,
      builder: (_) => _ViewPickerDialog(views: views, title: _viewTitle),
    );
    if (selected != null) _openRegisteredView(selected);
  }

  Future<void> _showNotificationsPanel() =>
      showShellNotifications(context, AppScope.of(context).services.shellNotifications, phone: _isPhoneLayout);

  String _viewTitle(ShellViewRegistration registration) {
    if (registration.isRoot && registration.destinationId != null) {
      return _config.destinations
              .where((destination) => destination.id == registration.destinationId)
              .firstOrNull
              ?.title(context) ??
          registration.title(context, registration.id);
    }
    return registration.title(context, registration.id);
  }

  Future<void> _maybePopCurrentPage() async {
    await navigatorKeys[currentDestinationId]?.currentState?.maybePop();
  }

  void _openInspector() {
    if (_activeInspectorBuilder == null) return;
    final width = MediaQuery.sizeOf(context).width;
    if (width < 1200) {
      final active = _activeTab;
      if (active != null) {
        _navigation.updateActive(active.copyWith(inspectorOpen: true));
      } else {
        _settingsController.update(_settingsController.settings.copyWith(inspectorOpen: true));
      }
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      _toggleInspector();
    }
  }

  Widget _buildHeader(double width, AppShellMetrics metrics) {
    final theme = Theme.of(context);
    final compact = width < 800;
    final shortcut = defaultTargetPlatform == TargetPlatform.macOS ? '⌘K' : (kIsWeb ? 'Ctrl+Shift+K' : 'Ctrl+K');
    final notificationService = AppScope.of(context).services.shellNotifications;

    return IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: Size.square(metrics.targetSize),
          maximumSize: Size.square(metrics.targetSize),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ),
      child: SizedBox(
        height: metrics.headerHeight,
        child: Row(
          children: [
            if (compact)
              IconButton(
                tooltip: context.l10n.navigationLabel,
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                icon: const Icon(Icons.menu),
              ),
            if (width >= 800)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_config.title(context), style: theme.textTheme.titleMedium),
              ),
            Expanded(
              child: Text(
                _activeTab == null ? _config.title(context) : _tabTitle(_activeTab!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge,
              ),
            ),
            if (_config.contexts.isNotEmpty) _buildContextPicker(width),
            if (_modules.isNotEmpty)
              PopupMenuButton<String>(
                tooltip: context.l10n.selectModule,
                onSelected: _selectModule,
                itemBuilder: (context) => _modules
                    .map((module) => PopupMenuItem(value: module.id, child: Text(module.title(context))))
                    .toList(),
                icon: const Icon(Icons.widgets_outlined),
              ),
            if (_tabs.length > 1 && width < 1200)
              PopupMenuButton<String>(
                tooltip: context.l10n.switchView,
                onSelected: _navigation.select,
                itemBuilder: (context) =>
                    _tabs.map((tab) => PopupMenuItem(value: tab.id, child: Text(_tabTitle(tab)))).toList(),
                icon: const Icon(Icons.tab),
              ),
            if (_activeTab != null &&
                (!_isPhoneLayout || _viewFor(_activeTab!.registrationId)?.isRoot != true) &&
                (_isPhoneLayout || width < 1200) &&
                (_viewFor(_activeTab!.registrationId)?.closeable ?? true))
              IconButton(
                tooltip: context.l10n.closeTab,
                onPressed: () => _closeTab(_activeTab!),
                icon: const Icon(Icons.close),
              ),
            if (_activeInspectorBuilder != null)
              IconButton(
                tooltip: context.l10n.openInspector,
                onPressed: _openInspector,
                icon: const Icon(Icons.vertical_split),
              ),
            AnimatedBuilder(
              animation: notificationService,
              builder: (context, _) => IconButton(
                tooltip: context.l10n.openNotifications,
                onPressed: _showNotificationsPanel,
                icon: Badge(
                  isLabelVisible: notificationService.unreadCount > 0,
                  label: Text(notificationService.unreadCount > 99 ? '99+' : '${notificationService.unreadCount}'),
                  child: const Icon(Icons.notifications_none),
                ),
              ),
            ),
            IconButton(
              tooltip: '${context.l10n.commandPalette} ($shortcut)',
              onPressed: _showCommandPalette,
              icon: const Icon(Icons.search),
            ),
            PopupMenuButton<String>(
              tooltip: context.l10n.moreActions,
              onSelected: (value) {
                if (value == 'theme') _toggleAppearance();
                if (value == 'layout') _restoreLayout();
                if (value == 'split') _toggleSplit();
                if (value == 'settings') unawaited(_openSettings());
                if (value == 'tab') unawaited(_showViewPicker());
              },
              itemBuilder: (context) => [
                if (_config.destinations.any((item) => item.id == 'settings' || item.id == 'page6'))
                  PopupMenuItem(value: 'settings', child: Text(context.l10n.openSettings)),
                PopupMenuItem(value: 'tab', child: Text(context.l10n.openViewTab)),
                PopupMenuItem(value: 'theme', child: Text(context.l10n.toggleAppearance)),
                if (_activeSplitBuilder != null)
                  PopupMenuItem(
                    value: 'split',
                    child: Text(_splitOpen ? context.l10n.closeSplitView : context.l10n.openSplitView),
                  ),
                PopupMenuItem(value: 'layout', child: Text(context.l10n.restoreLayout)),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildContextPicker(double width) {
    final selected = _selectedContext;
    if (selected == null) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: context.l10n.selectContext,
      onSelected: _selectContext,
      itemBuilder: (context) => _config.contexts
          .map((configured) => PopupMenuItem(value: configured.id, child: Text(configured.title(context))))
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
                    onSelect: () => _navigation.select(tab.id),
                    onClose: () => _closeTab(tab),
                    onContextMenu: (position) => _showTabMenu(tab, position),
                  ),
                );
              },
            ),
          ),
          IconButton(
            tooltip: context.l10n.openTabOverflow,
            onPressed: _tabs.isEmpty ? null : _showTabOverflow,
            icon: const Icon(Icons.more_horiz),
          ),
          IconButton(tooltip: context.l10n.openViewTab, onPressed: _showViewPicker, icon: const Icon(Icons.add)),
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
    if (action == 'close') _closeTab(tab);
    if (action == 'closeOthers') {
      _navigation.closeOthers(tab.id, canClose: _tabIsCloseable);
    }
    if (action == 'closeRight') _navigation.closeRight(tab.id, canClose: _tabIsCloseable);
    if (action == 'left') _moveTab(tab, -1);
    if (action == 'right') _moveTab(tab, 1);
  }

  bool _tabIsCloseable(String id) {
    final tab = _tabs.where((item) => item.id == id).firstOrNull;
    return tab != null && (_viewFor(tab.registrationId)?.closeable ?? true);
  }

  Future<void> _showTabOverflow() async {
    final id = await showDialog<String>(
      context: context,
      builder: (_) => _TabOverflowDialog(tabs: _tabs, title: _tabTitle),
    );
    if (id != null) _navigation.select(id);
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_config.title(context), style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final destination in _destinations)
              ListTile(
                selected: destination.id == currentDestinationId,
                leading: Icon(destination.icon),
                title: Text(destination.title(context)),
                onTap: () {
                  Navigator.of(context).pop();
                  unawaited(selectedPage(destination.id));
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspector({required bool drawer}) {
    final builder = _activeInspectorBuilder;
    if (builder == null) return const SizedBox.shrink();
    final content = Builder(
      builder: (context) {
        try {
          return builder(context);
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
                    final active = _activeTab;
                    if (active != null) {
                      _navigation.updateActive(active.copyWith(inspectorOpen: false));
                    } else {
                      _settingsController.update(_settingsController.settings.copyWith(inspectorOpen: false));
                    }
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
                return builder(context);
              } catch (error) {
                return Center(child: Text(context.l10n.shellContentError('$error')));
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar(AppShellMetrics metrics, double width) {
    final items =
        (_activeStatusProvider?.items ?? const <ShellStatusItem>[])
            .where((item) => item.isVisible?.call() ?? true)
            .toList()
          ..sort((left, right) => right.priority.compareTo(left.priority));
    if (items.isEmpty) return const SizedBox.shrink();
    final visibleCount = (width / 150).floor().clamp(1, items.length);
    final visible = items.take(visibleCount).toList();
    final overflow = items.skip(visibleCount).toList();
    final theme = Theme.of(context);
    return Container(
      height: metrics.statusHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          for (final item in visible)
            Flexible(
              child: Tooltip(
                message: item.tooltip ?? item.label,
                child: Semantics(
                  button: item.onTap != null,
                  label: '${_statusSeverityLabel(item.severity)} ${item.label}'.trim(),
                  child: TextButton.icon(
                    onPressed: item.onTap,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size(0, metrics.statusHeight),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: item.icon == null
                        ? const SizedBox.shrink()
                        : Icon(item.icon, size: 14, color: _statusColor(item.severity)),
                    label: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(color: _statusColor(item.severity)),
                    ),
                  ),
                ),
              ),
            ),
          if (overflow.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: context.l10n.moreActions,
              padding: EdgeInsets.zero,
              onSelected: (id) => overflow.where((item) => item.id == id).firstOrNull?.onTap?.call(),
              itemBuilder: (context) => overflow
                  .map((item) => PopupMenuItem(value: item.id, height: metrics.menuRowHeight, child: Text(item.label)))
                  .toList(),
              icon: const Icon(Icons.more_horiz, size: 16),
            ),
        ],
      ),
    );
  }

  Color _statusColor(ShellStatusSeverity severity) => switch (severity) {
    ShellStatusSeverity.normal => Theme.of(context).colorScheme.onSurfaceVariant,
    ShellStatusSeverity.success => Colors.green,
    ShellStatusSeverity.warning => Colors.orange,
    ShellStatusSeverity.error => Theme.of(context).colorScheme.error,
  };

  String _statusSeverityLabel(ShellStatusSeverity severity) => switch (severity) {
    ShellStatusSeverity.normal => '',
    ShellStatusSeverity.success => context.l10n.notificationSuccess,
    ShellStatusSeverity.warning => context.l10n.notificationWarning,
    ShellStatusSeverity.error => context.l10n.notificationError,
  };

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
        final compact = width < 800;
        final wide = width >= 1200;
        final visible = _destinations;
        final settings = _settingsController.settings;
        final metrics = AppTheme.metrics(context, phone: _isPhoneLayout);
        final showInspector = wide && _inspectorOpen && _activeInspectorBuilder != null;
        final availableInspectorWidth = (width - metrics.railWidth - 400).clamp(256.0, 440.0);
        final inspectorWidth = settings.inspectorWidth.clamp(256.0, availableInspectorWidth);
        final body = _activeContent(visible);

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
              SingleActivator(
                LogicalKeyboardKey.keyW,
                control: defaultTargetPlatform != TargetPlatform.macOS,
                meta: defaultTargetPlatform == TargetPlatform.macOS,
              ): () =>
                  _runShellShortcut(_closeActiveTab),
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
                  child: Scaffold(
                    key: _scaffoldKey,
                    resizeToAvoidBottomInset: true,
                    drawer: compact && !_isPhoneLayout ? _buildDrawer() : null,
                    endDrawer: _activeInspectorBuilder == null ? null : Drawer(child: _buildInspector(drawer: true)),
                    body: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          _buildHeader(width, metrics),
                          if (!_isPhoneLayout) _buildTabStrip(metrics),
                          Expanded(
                            child: Row(
                              children: [
                                if (!_isPhoneLayout && width >= 800)
                                  SideNavBar(
                                    currentId: currentDestinationId,
                                    destinations: visible,
                                    onSelected: (id) => unawaited(selectedPage(id)),
                                  ),
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
                          if (wide && !_isPhoneLayout) _buildStatusBar(metrics, width),
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
        );
      },
    );
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
