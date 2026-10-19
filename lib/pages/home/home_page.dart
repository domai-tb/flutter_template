import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'package:flutter_template/core/app_scope.dart';
import 'package:flutter_template/core/settings.dart';
import 'package:flutter_template/core/themes.dart';
import 'package:flutter_template/l10n/l10n_x.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';
import 'package:flutter_template/pages/home/widgets/bottom_nav_bar.dart';
import 'package:flutter_template/pages/home/widgets/page_navigation_animation.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<String, GlobalKey<NavigatorState>> navigatorKeys = {};
  final Map<String, GlobalKey<AnimatedExitState>> exitAnimationKeys = {};
  final Map<String, GlobalKey<AnimatedEntryState>> entryAnimationKeys = {};

  late final ShellConfig _config;
  late SettingsController _settingsController;
  String currentDestinationId = 'page1';
  String _selectedTabId = 'route';
  String? _selectedContextId;
  String? _selectedModuleId;
  double _splitRatio = 0.5;
  double pagePosition = 0;
  bool swipeDisabled = false;
  bool _settingsWired = false;
  bool _isPhoneLayout = true;
  bool _handlingPlatformRoute = false;
  bool _phonePageSyncScheduled = false;
  String? _lastPushedRouteId;
  List<ShellTabPreference> _tabs = const [ShellTabPreference(id: 'route', registrationId: 'route')];

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

  List<ShellTabPreference> _validTabs(Settings settings) {
    final registrations = _config.views.map((view) => view.id).toSet();
    final seen = <String>{};
    final result = settings.shellTabs.where((tab) {
      return registrations.contains(tab.registrationId) && seen.add(tab.id);
    }).toList();
    if (result.isEmpty || !result.any((tab) => tab.id == 'route')) {
      result.insert(0, const ShellTabPreference(id: 'route', registrationId: 'route'));
    }
    return result;
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
    if (id == currentDestinationId) return true;
    final destinations = _destinations;
    if (!destinations.any((destination) => destination.id == id)) return false;
    final oldId = currentDestinationId;

    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (_isPhoneLayout) {
      final index = destinations.indexWhere((destination) => destination.id == id);
      if (pageController.hasClients) {
        if (disableAnimations) {
          pageController.jumpToPage(index);
        } else {
          await pageController.animateToPage(index, duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
        }
      } else {
        setState(() => currentDestinationId = id);
      }
    } else if (disableAnimations) {
      setState(() => currentDestinationId = id);
    } else {
      exitAnimationKeys[id]?.currentState?.resetExitAnimation();
      await exitAnimationKeys[oldId]?.currentState?.startExitAnimation();
      if (!mounted) return false;
      setState(() => currentDestinationId = id);
      await entryAnimationKeys[id]?.currentState?.startEntryAnimation();
    }
    if (currentDestinationId != id && mounted) setState(() => currentDestinationId = id);
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
            setState(() => currentDestinationId = visible[index].id);
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
    final tabIndex = _tabs.indexWhere((tab) => tab.id == _selectedTabId).clamp(0, _tabs.length - 1);
    final tabStack = IndexedStack(
      index: tabIndex,
      children: _tabs.map((tab) {
        if (tab.registrationId == 'route') return _routeContent(visible);
        final registration = _viewFor(tab.registrationId);
        if (registration?.builder == null) return Center(child: Text(context.l10n.shellMissingView));
        try {
          return KeyedSubtree(key: ValueKey(tab.id), child: registration!.builder!(context));
        } catch (error) {
          return Center(child: Text(context.l10n.shellContentError('$error')));
        }
      }).toList(),
    );
    if (_selectedModuleId != null && _modules.isNotEmpty) {
      for (final module in _modules) {
        if (module.id == _selectedModuleId) {
          Widget content;
          try {
            content = module.builder(context);
          } catch (error) {
            content = Center(child: Text(context.l10n.shellContentError('$error')));
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              Offstage(child: tabStack),
              content,
            ],
          );
        }
      }
    }
    return tabStack;
  }

  void _persistTabs({List<ShellTabPreference>? tabs, String? selectedId}) {
    final nextTabs = tabs ?? _tabs;
    final nextSelectedId = selectedId ?? _selectedTabId;
    setState(() {
      _tabs = nextTabs;
      _selectedTabId = nextSelectedId;
    });
    _settingsController.update(
      _settingsController.settings.copyWith(shellTabs: nextTabs, selectedShellTabId: nextSelectedId),
    );
  }

  void _addPlaceholderTab() {
    var index = 1;
    while (_tabs.any((tab) => tab.id == 'placeholder-$index')) {
      index++;
    }
    final tabs = [..._tabs, ShellTabPreference(id: 'placeholder-$index', registrationId: 'placeholder')];
    _persistTabs(tabs: tabs, selectedId: 'placeholder-$index');
  }

  void _openRegisteredView(ShellViewRegistration registration) {
    var index = 1;
    while (_tabs.any((tab) => tab.id == '${registration.id}-$index')) {
      index++;
    }
    final id = '${registration.id}-$index';
    _persistTabs(
      tabs: [
        ..._tabs,
        ShellTabPreference(id: id, registrationId: registration.id),
      ],
      selectedId: id,
    );
  }

  void _closeTab(ShellTabPreference tab) {
    if (tab.id == 'route') return;
    final index = _tabs.indexOf(tab);
    final tabs = [..._tabs]..remove(tab);
    final next = tabs[index.clamp(0, tabs.length - 1)];
    _persistTabs(tabs: tabs, selectedId: tab.id == _selectedTabId ? next.id : _selectedTabId);
  }

  void _reorderTabs(int oldIndex, int newIndex) {
    final tabs = [..._tabs];
    final tab = tabs.removeAt(oldIndex);
    tabs.insert(newIndex.clamp(0, tabs.length), tab);
    _persistTabs(tabs: tabs);
  }

  void _moveTab(ShellTabPreference tab, int offset) {
    final index = _tabs.indexOf(tab);
    final nextIndex = index + offset;
    if (index < 0 || nextIndex < 0 || nextIndex >= _tabs.length) return;
    final tabs = [..._tabs]..removeAt(index);
    tabs.insert(nextIndex, tab);
    _persistTabs(tabs: tabs);
  }

  String _tabTitle(ShellTabPreference tab) {
    if (tab.registrationId == 'route') {
      return _config.destinations
              .where((destination) => destination.id == currentDestinationId)
              .firstOrNull
              ?.title(context) ??
          context.l10n.currentPageLabel;
    }
    return _viewFor(tab.registrationId)?.title(context, tab.id) ?? context.l10n.shellMissingView;
  }

  void _handleSettingsChanged() {
    if (!mounted) return;
    final valid = _validTabs(_settingsController.settings);
    final selected = valid.any((tab) => tab.id == _settingsController.settings.selectedShellTabId)
        ? _settingsController.settings.selectedShellTabId
        : valid.first.id;
    final configuredContext =
        _config.contexts
            .where((configured) => configured.id == _settingsController.settings.selectedContextId)
            .firstOrNull ??
        _config.contexts.firstOrNull;
    final selectedContextId = configuredContext?.id;
    final modules = configuredContext?.modules ?? _config.modules;
    final selectedModuleId = modules.any((module) => module.id == _settingsController.settings.selectedModuleId)
        ? _settingsController.settings.selectedModuleId
        : modules.firstOrNull?.id;
    final visible = _destinations;
    final nextDestination = visible.any((item) => item.id == currentDestinationId)
        ? currentDestinationId
        : visible.firstOrNull?.id;
    if (nextDestination != null && nextDestination != currentDestinationId) {
      currentDestinationId = nextDestination;
      final index = visible.indexWhere((item) => item.id == nextDestination);
      if (pageController.hasClients && index >= 0) pageController.jumpToPage(index);
    }
    setState(() {
      _tabs = valid;
      _selectedTabId = selected;
      _selectedContextId = selectedContextId;
      _selectedModuleId = selectedModuleId;
      _splitRatio = _settingsController.settings.splitRatio;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final supplied = widget.config ?? defaultShellConfig();
    final shellViews = defaultShellViews();
    final shellViewIds = shellViews.map((view) => view.id).toSet();
    _config = ShellConfig(
      title: supplied.title,
      destinations: supplied.destinations,
      views: [
        for (final view in shellViews) supplied.views.where((candidate) => candidate.id == view.id).firstOrNull ?? view,
        ...supplied.views.where((view) => !shellViewIds.contains(view.id)),
      ],
      modules: supplied.modules,
      contexts: supplied.contexts,
      inspectorBuilder: supplied.inspectorBuilder,
      splitPaneBuilder: supplied.splitPaneBuilder,
    );
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
    final validTabs = _validTabs(_settingsController.settings);
    _tabs = validTabs;
    _selectedTabId = validTabs.any((tab) => tab.id == _settingsController.settings.selectedShellTabId)
        ? _settingsController.settings.selectedShellTabId
        : validTabs.first.id;
    final settings = _settingsController.settings;
    _selectedContextId = _config.contexts.any((configured) => configured.id == settings.selectedContextId)
        ? settings.selectedContextId
        : _config.contexts.firstOrNull?.id;
    final visible = _destinations;
    final initialRoute = kIsWeb ? Uri.base.pathSegments.lastOrNull : null;
    if (visible.isNotEmpty) {
      currentDestinationId = visible.any((destination) => destination.id == initialRoute)
          ? initialRoute!
          : visible.first.id;
      _lastPushedRouteId = currentDestinationId;
    }
    _selectedModuleId = _modules.any((module) => module.id == settings.selectedModuleId)
        ? settings.selectedModuleId
        : _modules.firstOrNull?.id;
    _splitRatio = settings.splitRatio;
    _settingsWired = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_settingsWired) _settingsController.removeListener(_handleSettingsChanged);
    pageController.dispose();
    super.dispose();
  }

  Future<void> _openSettings() async {
    final destination = _config.destinations.where((item) => item.id == 'settings' || item.id == 'page6').firstOrNull;
    if (destination == null) return;
    await selectedPage(destination.id);
    if (!mounted) return;
    if (destination.id == 'page6') {
      final navigator = navigatorKeys[destination.id]?.currentState;
      navigator?.popUntil((route) => route.isFirst);
      navigator?.push<void>(MaterialPageRoute(builder: (_) => const Page6SettingsPage()));
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
    final settings = _settingsController.settings;
    _settingsController.update(settings.copyWith(inspectorOpen: !settings.inspectorOpen));
  }

  void _toggleSplit() {
    final settings = _settingsController.settings;
    _settingsController.update(settings.copyWith(splitOpen: !settings.splitOpen));
  }

  void _resizeSplit(double ratio, {bool persist = false}) {
    final next = ratio.clamp(0.3, 0.7);
    setState(() => _splitRatio = next);
    if (persist) _settingsController.update(_settingsController.settings.copyWith(splitRatio: next));
  }

  void _selectContext(String id) {
    final selected = _config.contexts.where((configured) => configured.id == id).firstOrNull;
    if (selected == null) return;
    final moduleId = selected.modules.firstOrNull?.id;
    setState(() {
      _selectedContextId = selected.id;
      _selectedModuleId = moduleId;
    });
    _settingsController.update(
      _settingsController.settings.copyWith(selectedContextId: selected.id, selectedModuleId: moduleId),
    );
  }

  void _selectModule(String id) {
    if (!_modules.any((module) => module.id == id)) return;
    setState(() => _selectedModuleId = id);
    _settingsController.update(_settingsController.settings.copyWith(selectedModuleId: id));
  }

  void _restoreLayout() {
    final settings = _settingsController.settings;
    final defaultContext = _config.contexts.firstOrNull;
    final defaultModules = defaultContext?.modules ?? _config.modules;
    _settingsController.update(
      settings.copyWith(
        inspectorOpen: false,
        inspectorWidth: 320,
        splitOpen: false,
        splitRatio: 0.5,
        shellTabs: const [ShellTabPreference(id: 'route', registrationId: 'route')],
        selectedShellTabId: 'route',
        selectedContextId: defaultContext?.id,
        selectedModuleId: defaultModules.firstOrNull?.id,
      ),
    );
    _announce(context.l10n.restoreLayout);
  }

  List<_ShellCommand> _commands() {
    final commands = <_ShellCommand>[
      if (_config.destinations.any((item) => item.id == 'settings' || item.id == 'page6'))
        _ShellCommand(id: 'settings', title: context.l10n.openSettings, shortcut: '', run: _openSettings),
      if (_config.inspectorBuilder != null)
        _ShellCommand(
          id: 'inspector',
          title: _settingsController.settings.inspectorOpen ? context.l10n.closeInspector : context.l10n.openInspector,
          shortcut: '',
          run: _toggleInspector,
        ),
      if (_config.splitPaneBuilder != null)
        _ShellCommand(
          id: 'split',
          title: _settingsController.settings.splitOpen ? context.l10n.closeSplitView : context.l10n.openSplitView,
          shortcut: '',
          run: _toggleSplit,
        ),
      _ShellCommand(id: 'layout', title: context.l10n.restoreLayout, shortcut: '', run: _restoreLayout),
      _ShellCommand(id: 'theme', title: context.l10n.toggleAppearance, shortcut: '', run: _toggleAppearance),
      _ShellCommand(id: 'new-tab', title: context.l10n.addPlaceholderTab, shortcut: '', run: _addPlaceholderTab),
    ];
    for (final view in _config.views.where((view) => view.id != 'route' && view.id != 'placeholder')) {
      commands.add(
        _ShellCommand(
          id: 'open-view-${view.id}',
          title: context.l10n.openView(view.title(context, view.id)),
          shortcut: '',
          run: () => _openRegisteredView(view),
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

  Future<void> _maybePopCurrentPage() async {
    await navigatorKeys[currentDestinationId]?.currentState?.maybePop();
  }

  void _openInspector() {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 1200) {
      _settingsController.update(_settingsController.settings.copyWith(inspectorOpen: true));
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      _toggleInspector();
    }
  }

  Widget _buildHeader(double width, double spacingScale) {
    final theme = Theme.of(context);
    final compact = width < 800;
    final shortcut = defaultTargetPlatform == TargetPlatform.macOS ? '⌘K' : (kIsWeb ? 'Ctrl+Shift+K' : 'Ctrl+K');

    return SizedBox(
      height: 52 * spacingScale,
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
              _destinations.where((item) => item.id == currentDestinationId).firstOrNull?.title(context) ??
                  _config.title(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ),
          if (_config.contexts.isNotEmpty) _buildContextPicker(width),
          if (_modules.isNotEmpty && width < 1200)
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
              onSelected: (id) => _persistTabs(selectedId: id),
              itemBuilder: (context) =>
                  _tabs.map((tab) => PopupMenuItem(value: tab.id, child: Text(_tabTitle(tab)))).toList(),
              icon: const Icon(Icons.tab),
            ),
          if (_selectedTabId != 'route' && width < 1200)
            IconButton(
              tooltip: context.l10n.closeTab,
              onPressed: () {
                final tab = _tabs.where((item) => item.id == _selectedTabId).firstOrNull;
                if (tab != null) _closeTab(tab);
              },
              icon: const Icon(Icons.close),
            ),
          if (_config.inspectorBuilder != null)
            IconButton(
              tooltip: context.l10n.openInspector,
              onPressed: _openInspector,
              icon: const Icon(Icons.vertical_split),
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
              if (value == 'tab') _addPlaceholderTab();
            },
            itemBuilder: (context) => [
              if (_config.destinations.any((item) => item.id == 'settings' || item.id == 'page6'))
                PopupMenuItem(value: 'settings', child: Text(context.l10n.openSettings)),
              PopupMenuItem(value: 'tab', child: Text(context.l10n.addPlaceholderTab)),
              PopupMenuItem(value: 'theme', child: Text(context.l10n.toggleAppearance)),
              if (_config.splitPaneBuilder != null)
                PopupMenuItem(
                  value: 'split',
                  child: Text(
                    _settingsController.settings.splitOpen ? context.l10n.closeSplitView : context.l10n.openSplitView,
                  ),
                ),
              PopupMenuItem(value: 'layout', child: Text(context.l10n.restoreLayout)),
            ],
          ),
          const SizedBox(width: 8),
        ],
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

  Widget _buildTabStrip(double spacingScale) {
    return SizedBox(
      height: 42 * spacingScale,
      child: Row(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              itemCount: _tabs.length,
              onReorderItem: _reorderTabs,
              itemBuilder: (context, index) {
                final tab = _tabs[index];
                final selected = tab.id == _selectedTabId;
                return Container(
                  key: ValueKey(tab.id),
                  margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
                  decoration: BoxDecoration(
                    color: selected ? Theme.of(context).colorScheme.surface : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: IconButton(
                          tooltip: context.l10n.reorderTab,
                          onPressed: () => _persistTabs(selectedId: tab.id),
                          icon: const Icon(Icons.drag_indicator, size: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _persistTabs(selectedId: tab.id),
                        child: Text(_tabTitle(tab), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (tab.id != 'route')
                        IconButton(
                          tooltip: context.l10n.closeTab,
                          onPressed: () => _closeTab(tab),
                          icon: const Icon(Icons.close, size: 16),
                        ),
                      if (tab.id != 'route')
                        PopupMenuButton<String>(
                          tooltip: context.l10n.tabActions,
                          onSelected: (action) {
                            if (action == 'left') _moveTab(tab, -1);
                            if (action == 'right') _moveTab(tab, 1);
                            if (action == 'close') _closeTab(tab);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'left',
                              enabled: _tabs.indexOf(tab) > 0,
                              child: Text(context.l10n.moveLeft),
                            ),
                            PopupMenuItem(
                              value: 'right',
                              enabled: _tabs.indexOf(tab) < _tabs.length - 1,
                              child: Text(context.l10n.moveRight),
                            ),
                            PopupMenuItem(value: 'close', child: Text(context.l10n.closeTab)),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          IconButton(
            tooltip: context.l10n.addPlaceholderTab,
            onPressed: _addPlaceholderTab,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildModules(double spacingScale) {
    if (_modules.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 42 * spacingScale,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _modules.map((module) {
          final selected = module.id == _selectedModuleId;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              onPressed: () => _selectModule(module.id),
              child: Text(
                module.title(context),
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
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
    final builder = _config.inspectorBuilder;
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
                    _settingsController.update(_settingsController.settings.copyWith(inspectorOpen: false));
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
    final builder = _config.splitPaneBuilder;
    if (!wide || builder == null || !_settingsController.settings.splitOpen || width < 824) return primary;
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

  Widget _buildStatusBar() {
    final title =
        _destinations.where((item) => item.id == currentDestinationId).firstOrNull?.title(context) ??
        context.l10n.shellNoDestinations;
    return Container(
      height: 26 * (Theme.of(context).extension<AppShellTokens>()?.spacingScale ?? 1),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Text(context.l10n.shellReady, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.labelSmall)),
          Text(
            _isPhoneLayout ? context.l10n.phoneLayout : context.l10n.desktopLayout,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
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
        _isPhoneLayout = width < 600;
        final compact = width < 800;
        final wide = width >= 1200;
        final visible = _destinations;
        final settings = _settingsController.settings;
        final spacingScale = Theme.of(context).extension<AppShellTokens>()?.spacingScale ?? 1;
        final showInspector = wide && settings.inspectorOpen && _config.inspectorBuilder != null;
        final availableInspectorWidth = (width - 72 - 400).clamp(256.0, 440.0);
        final inspectorWidth = settings.inspectorWidth.clamp(256.0, availableInspectorWidth);
        final body = _activeContent(visible);

        return CallbackShortcuts(
          bindings: {
            SingleActivator(
              LogicalKeyboardKey.keyK,
              control: !kIsWeb && defaultTargetPlatform != TargetPlatform.macOS,
              meta: defaultTargetPlatform == TargetPlatform.macOS,
            ): _showCommandPalette,
            if (kIsWeb) const SingleActivator(LogicalKeyboardKey.keyK, control: true, shift: true): _showCommandPalette,
            const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true, shift: true): () {
              if (_tabs.isNotEmpty) {
                final index = _tabs.indexWhere((tab) => tab.id == _selectedTabId);
                _persistTabs(selectedId: _tabs[(index + 1) % _tabs.length].id);
              }
            },
            const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true, shift: true): () {
              if (_tabs.isNotEmpty) {
                final index = _tabs.indexWhere((tab) => tab.id == _selectedTabId);
                _persistTabs(selectedId: _tabs[(index - 1 + _tabs.length) % _tabs.length].id);
              }
            },
            const SingleActivator(LogicalKeyboardKey.keyW, alt: true, shift: true): () {
              final tab = _tabs.where((item) => item.id == _selectedTabId).firstOrNull;
              if (tab != null) _closeTab(tab);
            },
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
                child: Scaffold(
                  key: _scaffoldKey,
                  resizeToAvoidBottomInset: true,
                  drawer: compact ? _buildDrawer() : null,
                  endDrawer: _config.inspectorBuilder == null ? null : Drawer(child: _buildInspector(drawer: true)),
                  body: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        _buildHeader(width, spacingScale),
                        if (wide) _buildModules(spacingScale),
                        if (wide) _buildTabStrip(spacingScale),
                        Expanded(
                          child: Row(
                            children: [
                              if (width >= 800)
                                SideNavBar(
                                  currentId: currentDestinationId,
                                  destinations: visible,
                                  onSelected: (id) => unawaited(selectedPage(id)),
                                ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(wide ? 8 * spacingScale : 0),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) => _buildSplit(
                                      body,
                                      constraints.maxWidth - (wide ? 16 * spacingScale : 0),
                                      wide: wide,
                                    ),
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
                        if (wide) _buildStatusBar(),
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
