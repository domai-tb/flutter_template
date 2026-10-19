import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/core/app_scope.dart';
import 'package:flutter_template/core/app_services.dart';
import 'package:flutter_template/core/injection.dart' as ic;
import 'package:flutter_template/core/settings.dart';
import 'package:flutter_template/core/themes.dart';
import 'package:flutter_template/l10n/l10n.dart';
import 'package:flutter_template/pages/home/home_page.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';
import 'package:flutter_template/pages/home/shell_navigation_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ic.init();
  });

  tearDown(() async => ic.sl.reset());

  testWidgets('sections keep independent tabs, active selection, and live state', (tester) async {
    final config = _config();
    await _pumpShell(tester, config: config);
    final home = tester.state<HomePageState>(find.byType(HomePage));
    final settings = ic.sl<SettingsController>();

    final a1 = home.openView('editor', sectionId: 'activity-a', instanceId: 'a1', parameters: {'document': 'A1'})!;
    final a2 = home.openView('editor', sectionId: 'activity-a', instanceId: 'a2', parameters: {'document': 'A2'})!;
    final a3 = home.openView('editor', sectionId: 'activity-a', instanceId: 'a3', parameters: {'document': 'A3'})!;
    await tester.pumpAndSettle();
    var navigation = _navigation(tester, 'A3');
    expect(_workspace(settings, 'activity-a').tabs.map((tab) => tab.id), [a1, a2, a3]);
    expect({a1, a2, a3}.length, 3);
    expect(_workspace(settings, 'activity-a').tabs.every((tab) => tab.sectionId == 'activity-a'), isTrue);
    navigation.selectTab('activity-a', a2);
    expect(navigation.selectedSectionId, 'activity-a');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('increment-a2')));
    await tester.tap(find.byKey(const ValueKey('increment-a2')));
    await tester.pump();

    await home.selectedPage('activity-b');
    await tester.pumpAndSettle();
    expect(navigation.selectedSectionId, 'activity-b');
    expect(_workspace(settings, 'activity-b').tabs, isEmpty);
    expect(find.text('Document A2'), findsNothing);
    await tester.tap(find.byTooltip('Open right sidebar'));
    await tester.pumpAndSettle();
    expect(find.text('No tab is active.'), findsOneWidget);
    await tester.drag(find.byIcon(Icons.drag_indicator), const Offset(-32, 0));
    await tester.pumpAndSettle();
    final resizedInspectorWidth = settings.settings.inspectorWidth;
    expect(resizedInspectorWidth, greaterThan(320));
    final b1 = home.openView('editor', sectionId: 'activity-b', instanceId: 'b1', parameters: {'document': 'B1'})!;
    final b2 = home.openView('editor', sectionId: 'activity-b', instanceId: 'b2', parameters: {'document': 'B2'})!;
    await tester.pumpAndSettle();
    navigation = _navigation(tester, 'B2');
    navigation.selectTab('activity-b', b1);
    await tester.pumpAndSettle();
    expect(find.text('Document B1'), findsOneWidget);
    expect(find.text('Inspector b1'), findsOneWidget);
    expect(_workspace(settings, 'activity-b').tabs.every((tab) => tab.sectionId == 'activity-b'), isTrue);

    await home.selectedPage('activity-a');
    await tester.pumpAndSettle();
    expect(navigation.selectedSectionId, 'activity-a');
    expect(find.text('Document A2'), findsOneWidget);
    expect(find.text('Inspector a2'), findsOneWidget);
    expect(find.text('Count: 2'), findsOneWidget);
    expect(_workspace(settings, 'activity-a').activeTabId, a2);
    expect(_workspace(settings, 'activity-b').activeTabId, b1);
    expect(_workspace(settings, 'activity-b').tabs.map((tab) => tab.id), [b1, b2]);
    expect(settings.settings.inspectorWidth, resizedInspectorWidth);

    await home.selectedPage('activity-a');
    await tester.pumpAndSettle();
    expect(find.text('Document A2'), findsOneWidget);
    final a4 = home.openView('editor', sectionId: 'activity-a', instanceId: 'a4', parameters: {'document': 'A4'})!;
    await tester.pumpAndSettle();
    expect(_workspace(settings, 'activity-a').tabs, hasLength(4));
    expect(_workspace(settings, 'activity-b').tabs, hasLength(2));

    navigation = _navigation(tester, 'A4');
    navigation.reorderTabs('activity-a', 3, 0);
    navigation.selectTab('activity-a', a2);
    navigation.closeTab('activity-a', a1, closable: true);
    await tester.pumpAndSettle();
    expect(_workspace(settings, 'activity-a').tabs.map((tab) => tab.id), [a4, a2, a3]);
    expect(_workspace(settings, 'activity-a').activeTabId, a2);
    expect(_workspace(settings, 'activity-b').tabs.map((tab) => tab.id), [b1, b2]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final restoredSettings = await SettingsController.load();
    addTearDown(restoredSettings.dispose);
    await tester.pumpWidget(_app(config, settings: restoredSettings));
    await tester.pumpAndSettle();
    expect(_workspace(restoredSettings, 'activity-a').tabs.map((tab) => tab.id), [a4, a2, a3]);
    expect(_workspace(restoredSettings, 'activity-a').activeTabId, a2);
    expect(_workspace(restoredSettings, 'activity-b').tabs.map((tab) => tab.id), [b1, b2]);
    expect(_workspace(restoredSettings, 'activity-b').activeTabId, b1);
    expect(find.text('Document A2'), findsOneWidget);
    expect(find.text('Restored: true'), findsOneWidget);

    final restoredHome = tester.state<HomePageState>(find.byType(HomePage));
    await restoredHome.selectedPage('activity-b');
    await tester.pumpAndSettle();
    Focus.of(tester.element(find.byType(AnnotatedRegion<SystemUiOverlayStyle>))).requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(_workspace(restoredSettings, 'activity-b').activeTabId, b2);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(_workspace(restoredSettings, 'activity-a').tabs.map((tab) => tab.id), [a4, a2, a3]);
    expect(_workspace(restoredSettings, 'activity-b').tabs.map((tab) => tab.id), [b1]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  test('coordinator supports large workspaces and explicit reuse policies', () {
    ShellDestination section(String id) => ShellDestination(
      id: id,
      title: (_) => id,
      icon: Icons.home,
      allowedViewIds: const {'new', 'registration', 'instance'},
    );
    ShellViewRegistration view(String id, ShellViewReusePolicy policy) => ShellViewRegistration(
      id: id,
      title: (_, instanceId) => instanceId,
      reusePolicy: policy,
      viewBuilder: (_, _) => const SizedBox.shrink(),
    );

    final navigation = ShellNavigationCoordinator(
      sections: [section('a'), section('b'), section('c')],
      views: [
        view('new', ShellViewReusePolicy.never),
        view('registration', ShellViewReusePolicy.byRegistration),
        view('instance', ShellViewReusePolicy.byInstance),
      ],
    );
    addTearDown(navigation.dispose);

    final firstNew = navigation.openTab('a', 'new');
    final secondNew = navigation.openTab('a', 'new');
    expect(secondNew, isNot(firstNew));

    final byRegistration = navigation.openTab('a', 'registration', instanceId: 'resource-a');
    expect(navigation.openTab('a', 'registration', instanceId: 'resource-b'), byRegistration);
    expect(
      navigation.openTab('b', 'registration', instanceId: 'resource-a', activateSection: false),
      isNot(byRegistration),
    );

    final firstInstance = navigation.openTab('a', 'instance', instanceId: 'item-1');
    expect(navigation.openTab('a', 'instance', instanceId: 'item-1'), firstInstance);
    expect(navigation.openTab('a', 'instance', instanceId: 'item-2'), isNot(firstInstance));

    for (var index = 0; index < 50; index++) {
      navigation.openTab('b', 'new', instanceId: 'large-$index', activateSection: false);
    }
    expect(navigation.workspaceFor('a').tabs, hasLength(5));
    expect(navigation.workspaceFor('b').tabs, hasLength(51));
    expect(navigation.workspaceFor('a').tabs.where((tab) => tab.registrationId == 'new'), hasLength(2));
    expect(navigation.workspaceFor('b').tabs.where((tab) => tab.registrationId == 'new'), hasLength(50));
    expect(navigation.workspaceFor('c').tabs, isEmpty);
    expect(navigation.selectedSectionId, 'a');

    final reusedTab = navigation.openTab('c', 'registration', instanceId: 'resource-c');
    final newTab = navigation.openTab('c', 'registration', instanceId: 'resource-c', forceNew: true);
    expect(newTab, isNot(reusedTab));
    expect(navigation.workspaceFor('c').tabs, hasLength(2));
  });

  test('restoration retains unavailable section and view records', () {
    final config = _config();
    final navigation = ShellNavigationCoordinator(sections: config.destinations, views: config.views);
    addTearDown(navigation.dispose);

    navigation.restoreWorkspaces([
      const ShellWorkspacePreference(
        sectionId: 'activity-a',
        tabs: [ShellTabPreference(id: 'known-tab', sectionId: 'activity-a', registrationId: 'editor')],
        activeTabId: 'known-tab',
      ),
      const ShellWorkspacePreference(
        sectionId: 'retired-section',
        tabs: [
          ShellTabPreference(
            id: 'retired-tab',
            sectionId: 'retired-section',
            registrationId: 'removed-view',
            parameters: {'opaque': 'preserve'},
          ),
        ],
        activeTabId: 'retired-tab',
      ),
    ], selectedSectionId: 'activity-a');

    final saved = Settings(
      shellWorkspaces: navigation.workspaces.map((workspace) => workspace.toPreference()).toList(),
    );
    final restored = Settings.fromJson(saved.toJson());
    final retired = restored.shellWorkspaces.singleWhere((workspace) => workspace.sectionId == 'retired-section');

    expect(navigation.selectedSectionId, 'activity-a');
    expect(navigation.workspaceFor('activity-a').tabs.single.id, 'known-tab');
    expect(retired.activeTabId, 'retired-tab');
    expect(retired.tabs.single.registrationId, 'removed-view');
    expect(retired.tabs.single.parameters, {'opaque': 'preserve'});
  });

  testWidgets('narrow desktop keeps the generic right sidebar available in a drawer', (tester) async {
    await _pumpShell(tester, config: _config(), size: const Size(960, 700));
    expect(find.byTooltip('Open right sidebar'), findsOneWidget);

    await tester.tap(find.byTooltip('Open right sidebar'));
    await tester.pumpAndSettle();
    expect(find.text('No tab is active.'), findsOneWidget);
    final drawer = find.ancestor(of: find.text('No tab is active.'), matching: find.byType(Drawer));
    await tester.tap(find.descendant(of: drawer, matching: find.byTooltip('Close right sidebar')));
    await tester.pumpAndSettle();
    expect(find.text('No tab is active.'), findsNothing);
    expect(ic.sl<SettingsController>().settings.inspectorOpen, isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('flat saved tabs migrate by destination and retain unavailable registrations', (tester) async {
    final settings = ic.sl<SettingsController>();
    settings.update(
      settings.settings.copyWith(
        shellTabs: const [
          ShellTabPreference(id: 'unknown-tab', registrationId: 'removed-view'),
          ShellTabPreference(
            id: 'saved-editor',
            registrationId: 'editor',
            instanceId: 'saved',
            parameters: {'document': 'saved'},
            destinationId: 'activity-b',
          ),
        ],
        selectedShellTabId: 'unknown-tab',
        selectedActivityId: 'activity-a',
      ),
    );
    await _pumpShell(tester);

    expect(settings.settings.shellWorkspaces, isNotEmpty);
    expect(_workspace(settings, 'activity-a').tabs.single.registrationId, 'removed-view');
    expect(_workspace(settings, 'activity-b').tabs.single.parameters['document'], 'saved');
    expect(tester.takeException(), isNull);

    final home = tester.state<HomePageState>(find.byType(HomePage));
    await home.selectedPage('activity-b');
    await tester.pumpAndSettle();
    expect(find.text('Document saved'), findsOneWidget);
    expect(_workspace(settings, 'activity-b').tabs.single.instanceId, 'saved');
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('all default sections open content and keep the generic inspector available', (tester) async {
    await _pumpShell(tester, config: defaultShellConfig());
    final home = tester.state<HomePageState>(find.byType(HomePage));
    final settings = ic.sl<SettingsController>();

    for (final item in PageItem.values) {
      await home.selectedPage(item.name);
      await tester.pumpAndSettle();
      expect(_workspace(settings, item.name).tabs, isNotEmpty, reason: '${item.name} should have its default view');
      final workspace = _workspace(settings, item.name);
      expect(workspace.tabs.singleWhere((tab) => tab.id == workspace.activeTabId).registrationId, item.name);
      expect(
        find.byKey(ValueKey('workspace-tab-${workspace.activeTabId}')),
        findsOneWidget,
        reason: '${item.name} should mount its configured content',
      );
      expect(
        find.text(pageItemPresentation(tester.element(find.byType(HomePage)), item).title),
        findsAtLeastNWidgets(1),
      );
    }

    final active = settings.settings.selectedActivityId!;
    await home.selectedPage(active);
    await tester.pumpAndSettle();
    expect(_workspace(settings, active).tabs, isNotEmpty);
    expect(find.byTooltip('Open right sidebar'), findsOneWidget);
    await tester.tap(find.byTooltip('Open right sidebar'));
    await tester.pumpAndSettle();
    expect(find.text('Workspace'), findsOneWidget);

    await home.selectedPage('page1');
    await tester.pumpAndSettle();
    final page1 = _workspace(settings, 'page1');
    expect(find.byKey(ValueKey('workspace-tab-${page1.activeTabId}')), findsOneWidget);

    home.openView('page1', sectionId: 'page1');
    home.openView('page1', sectionId: 'page1');
    home.openView('page2', sectionId: 'page2');
    await tester.pumpAndSettle();
    final page1Tabs = _workspace(settings, 'page1').tabs;
    final page2Tabs = _workspace(settings, 'page2').tabs;
    expect(page1Tabs, hasLength(3));
    expect(page1Tabs.map((tab) => tab.id).toSet(), hasLength(3));
    expect(page2Tabs, hasLength(2));
    expect(page2Tabs.map((tab) => tab.id).toSet(), hasLength(2));
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('commands, contextual right sidebar, status, and middle click follow the active section tab', (
    tester,
  ) async {
    final actions = <String>[];
    final providers = <String, _WorkspaceStatusProvider>{};
    final config = _config(onAction: actions.add, providers: providers);
    await _pumpShell(tester, config: config);
    final home = tester.state<HomePageState>(find.byType(HomePage));
    final editorId = home.openView('editor', instanceId: 'one', parameters: {'document': 'alpha'})!;
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('header-action-command-palette')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Open view: Help');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open view: Help').last);
    await tester.pumpAndSettle();
    expect(find.text('Help view'), findsOneWidget);
    expect(find.text('Status one'), findsNothing);
    expect(ic.sl<SettingsController>().settings.selectedShellTabId, isNot(editorId));

    await tester.tap(find.byTooltip('Editor one'));
    await tester.pumpAndSettle();
    expect(find.text('Status one'), findsOneWidget);
    await tester.tap(find.byTooltip('Pin editor one'));
    expect(actions, ['one']);
    await tester.tap(find.byTooltip('Open right sidebar'));
    await tester.pumpAndSettle();
    expect(find.text('Inspector one'), findsOneWidget);

    final editorTab = tester.getCenter(find.byTooltip('Editor one').first);
    tester.binding.handlePointerEvent(
      PointerDownEvent(pointer: 42, kind: PointerDeviceKind.mouse, position: editorTab, buttons: kMiddleMouseButton),
    );
    tester.binding.handlePointerEvent(PointerUpEvent(pointer: 42, kind: PointerDeviceKind.mouse, position: editorTab));
    await tester.pumpAndSettle();
    expect(ic.sl<SettingsController>().settings.shellTabs.any((tab) => tab.id == editorId), isFalse);
    expect(find.text('Help view'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('mobile switches tabs within the selected section without a desktop tab strip', (tester) async {
    await _pumpShell(tester, config: _config(), size: const Size(390, 844));
    final home = tester.state<HomePageState>(find.byType(HomePage));
    home.openView('editor', instanceId: 'one', parameters: {'document': 'alpha'});
    home.openView('editor', instanceId: 'two', parameters: {'document': 'beta'});
    await tester.pumpAndSettle();

    expect(find.byTooltip('Switch view'), findsOneWidget);
    expect(find.byType(ReorderableListView), findsNothing);
    expect(find.text('Document beta'), findsOneWidget);
    await tester.tap(find.byTooltip('Switch view'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editor one'));
    await tester.pumpAndSettle();
    expect(find.text('Document alpha'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}

ShellConfig _config({
  void Function(String instanceId)? onAction,
  Map<String, _WorkspaceStatusProvider>? providers,
}) => ShellConfig(
  title: (_) => 'Workspace test',
  destinations: const [
    ShellDestination(id: 'activity-a', title: _activityTitleA, icon: Icons.home, allowedViewIds: {'editor', 'help'}),
    ShellDestination(id: 'activity-b', title: _activityTitleB, icon: Icons.folder, allowedViewIds: {'editor', 'help'}),
  ],
  views: [
    ShellViewRegistration(
      id: 'editor',
      title: (_, instanceId) => 'Editor $instanceId',
      icon: Icons.description_outlined,
      viewBuilder: (context, view) => _EditorView(
        instanceId: view.instanceId,
        document: view.parameters['document'] as String? ?? '',
        isRestored: view.isRestored,
      ),
      toolbarActionsBuilder: (_, view) => [
        ShellViewAction(
          id: 'pin',
          label: 'Pin editor ${view.instanceId}',
          icon: Icons.push_pin_outlined,
          onPressed: () => onAction?.call(view.instanceId),
        ),
      ],
      inspectorBuilder: (_, view) => Text('Inspector ${view.instanceId}'),
      statusProviderFactory: (id) {
        final provider = _WorkspaceStatusProvider(id);
        providers?[id] = provider;
        return provider;
      },
    ),
    ShellViewRegistration(
      id: 'help',
      title: (_, _) => 'Help',
      viewBuilder: (_, _) => const Center(child: Text('Help view')),
    ),
  ],
);

String _activityTitleA(BuildContext _) => 'Activity A';
String _activityTitleB(BuildContext _) => 'Activity B';

Future<void> _pumpShell(WidgetTester tester, {ShellConfig? config, Size size = const Size(1440, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app(config ?? _config()));
  await tester.pumpAndSettle();
}

Widget _app(ShellConfig config, {SettingsController? settings}) {
  final controller = settings ?? ic.sl<SettingsController>();
  return AppScope(
    settings: controller,
    services: ic.sl<AppServices>(),
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = controller.settings;
        return MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(accentPreset: value.accentPreset, comfortable: value.density == 'comfortable'),
          darkTheme: AppTheme.dark(accentPreset: value.accentPreset, comfortable: value.density == 'comfortable'),
          themeMode: value.useDarkmode ? ThemeMode.dark : ThemeMode.light,
          home: HomePage(mainNavigatorKey: GlobalKey<NavigatorState>(), config: config),
        );
      },
    ),
  );
}

ShellWorkspacePreference _workspace(SettingsController settings, String sectionId) =>
    settings.settings.shellWorkspaces.firstWhere((workspace) => workspace.sectionId == sectionId);

ShellNavigationCoordinator _navigation(WidgetTester tester, String document) =>
    ShellWorkspace.of(tester.element(find.text('Document $document')));

class _EditorView extends StatefulWidget {
  final String instanceId;
  final String document;
  final bool isRestored;

  const _EditorView({required this.instanceId, required this.document, required this.isRestored});

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> {
  int count = 0;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('Document ${widget.document}'),
      Text('Count: $count'),
      Text('Restored: ${widget.isRestored}'),
      FilledButton(
        key: ValueKey('increment-${widget.instanceId}'),
        onPressed: () => setState(() => count++),
        child: const Text('Increment'),
      ),
      TextButton(
        onPressed: () => ShellWorkspace.of(context).openView('help'),
        child: const Text('Open help from editor'),
      ),
    ],
  );
}

class _WorkspaceStatusProvider extends ShellStatusProvider {
  _WorkspaceStatusProvider(this.instanceId);

  final String instanceId;

  @override
  List<ShellStatusItem> get items => [ShellStatusItem(id: instanceId, label: 'Status $instanceId')];
}
