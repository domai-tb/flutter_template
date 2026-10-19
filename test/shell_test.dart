import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/core/app_scope.dart';
import 'package:flutter_template/core/app_services.dart';
import 'package:flutter_template/core/injection.dart' as ic;
import 'package:flutter_template/core/settings.dart';
import 'package:flutter_template/core/shell_notifications.dart';
import 'package:flutter_template/l10n/l10n.dart';
import 'package:flutter_template/pages/home/home_page.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';
import 'package:flutter_template/widgets/app_segmented_triple_control.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ic.init();
  });

  tearDown(() async {
    await ic.sl.reset();
  });

  test('old settings survive migration and unknown preferences are retained', () {
    final settings = Settings.fromJson({
      'useSystemDarkmode': true,
      'useDarkmode': false,
      'useSystemTextScaling': false,
      'didCompleteOnboarding': true,
      'localeCode': 'de',
      'navBarItemOrder': ['page3', 'page1'],
      'hiddenNavBarItems': ['page2', 'page6'],
      'localFeatureFlag': true,
      'accentPreset': 'unknown',
      'density': 'unknown',
      'inspectorWidth': -20,
      'splitRatio': 2,
      'splitOpen': true,
    });

    expect(settings.useSystemDarkmode, isTrue);
    expect(settings.useDarkmode, isFalse);
    expect(settings.useSystemTextScaling, isFalse);
    expect(settings.didCompleteOnboarding, isTrue);
    expect(settings.localeCode, 'de');
    expect(settings.navBarItemOrder, ['page3', 'page1']);
    expect(settings.hiddenNavBarItems, ['page2']);
    expect(settings.accentPreset, 'steel');
    expect(settings.density, 'compact');
    expect(settings.inspectorWidth, 256);
    expect(settings.splitRatio, 0.7);
    expect(settings.splitOpen, isTrue);
    expect(settings.toJson()['localFeatureFlag'], isTrue);
  });

  test('new settings default to dark and accessibility scaling', () {
    const settings = Settings();
    expect(settings.useSystemDarkmode, isFalse);
    expect(settings.useDarkmode, isTrue);
    expect(settings.useSystemTextScaling, isTrue);
  });

  test('notification history is bounded and evicts read entries first', () {
    final service = ShellNotificationService();
    addTearDown(service.dispose);
    final readId = service.add(severity: ShellNotificationSeverity.info, title: 'Read');
    service.markRead(readId);
    for (var index = 0; index < ShellNotificationService.capacity; index++) {
      service.add(severity: ShellNotificationSeverity.info, title: 'Event $index');
    }
    expect(service.notifications, hasLength(ShellNotificationService.capacity));
    expect(service.notifications.any((item) => item.id == readId), isFalse);

    final oldestUnread = service.notifications.last.id;
    service.add(severity: ShellNotificationSeverity.warning, title: 'Newest');
    expect(service.notifications, hasLength(ShellNotificationService.capacity));
    expect(service.notifications.any((item) => item.id == oldestUnread), isFalse);
    expect(service.unreadCount, ShellNotificationService.capacity);
  });

  testWidgets('registered destinations use the shared shell layout', (tester) async {
    final config = _testConfig();
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settings = ic.sl<SettingsController>();
    settings.update(
      settings.settings.copyWith(
        shellTabs: const [
          ShellTabPreference(id: 'route', registrationId: 'route'),
          ShellTabPreference(id: 'placeholder-1', registrationId: 'placeholder'),
        ],
        selectedShellTabId: 'route',
      ),
    );

    await tester.pumpWidget(_app(config));
    await tester.pumpAndSettle();

    expect(find.text('Registered page'), findsOneWidget);
    expect(find.text('Registered destination'), findsWidgets);
    expect(find.text('Ready'), findsNothing);
    expect(settings.settings.shellTabs.map((tab) => tab.id), ['test']);

    final home = tester.state<HomePageState>(find.byType(HomePage));
    await home.selectedPage('test');
    await home.selectedPage('test');
    await tester.pumpAndSettle();
    expect(settings.settings.shellTabs.map((tab) => tab.id), ['test']);

    await tester.tap(find.byTooltip('Open view'));
    await tester.pumpAndSettle();
    expect(find.text('Registered view'), findsWidgets);
    await tester.tap(find.text('Registered view').last);
    await tester.pumpAndSettle();
    expect(find.text('Registered view content'), findsOneWidget);
    expect(find.text('Status registered-view-1'), findsOneWidget);

    await home.selectedPage('test');
    await tester.pumpAndSettle();
    expect(find.text('Status registered-view-1'), findsNothing);
    await tester.tap(find.byTooltip('Open view'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registered view').last);
    await tester.pumpAndSettle();
    expect(find.text('Status registered-view-2'), findsOneWidget);
    await tester.tap(find.text('Registered view 1'));
    await tester.pumpAndSettle();
    expect(find.text('Status registered-view-1'), findsOneWidget);
    expect(settings.settings.shellTabs.map((tab) => tab.id), ['test', 'registered-view-1', 'registered-view-2']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('notification actions read and clear events', (tester) async {
    final service = ic.sl<AppServices>().shellNotifications;
    var actionCalled = false;
    service.add(
      severity: ShellNotificationSeverity.success,
      title: 'Preview event',
      message: 'A registered view reported an event.',
      onAction: () => actionCalled = true,
    );
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(_testConfig()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Preview event'), findsOneWidget);
    await tester.tap(find.text('Preview event'));
    await tester.pumpAndSettle();
    expect(actionCalled, isTrue);
    expect(service.unreadCount, 0);

    await tester.tap(find.byTooltip('Clear all'));
    await tester.pumpAndSettle();
    expect(find.text('No notifications'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('command palette opens a registered view by its stable id', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(_testConfig()));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.text('Search shell commands'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Open view');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open view: Registered view'));
    await tester.pumpAndSettle();
    expect(find.text('Registered view content'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('shell adapts to phone, compact, medium and wide constraints', (tester) async {
    final config = _testConfig();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in [
      const Size(390, 700),
      const Size(390, 900),
      const Size(600, 700),
      const Size(720, 900),
      const Size(960, 700),
      const Size(1200, 900),
      const Size(1440, 700),
      const Size(1440, 900),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(_app(config));
      await tester.pumpAndSettle();
      final reason = 'size ${size.width} × ${size.height}';
      expect(tester.takeException(), isNull, reason: reason);
      expect(find.text('Registered page'), findsOneWidget, reason: reason);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('error slot only offers retry when a callback is supplied', (tester) async {
    const localizations = MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ShellContentSlot(state: ShellSlotState.error, message: 'Unavailable'),
    );
    await tester.pumpWidget(localizations);
    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShellContentSlot(state: ShellSlotState.error, message: 'Unavailable', onRetry: () {}),
      ),
    );
    expect(find.text('Retry'), findsOneWidget);

    await tester.pumpWidget(
      _app(
        ShellConfig(
          title: (_) => 'Error test',
          destinations: [
            ShellDestination(
              id: 'broken',
              title: (_) => 'Broken',
              icon: Icons.error_outline,
              lockedVisible: true,
              builder: (_, _, _, _) => throw StateError('intentional'),
            ),
          ],
        ),
      ),
    );
    expect(find.textContaining('intentional'), findsOneWidget);
    expect(find.byTooltip('More actions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('segmented settings control tracks parent updates', (tester) async {
    var selection = 2;
    late StateSetter updateParent;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateParent = setState;
              return AppSegmentedTripleControl(
                leftTitle: 'System',
                centerTitle: 'Light',
                rightTitle: 'Dark',
                initialSelection: selection,
                onChanged: (value) => setState(() => selection = value),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Light'));
    expect(selection, 1);
    updateParent(() => selection = 0);
    await tester.pump();
    expect(tester.widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>)).selected, {0});
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('configured contexts switch modules and persist their stable ids', (tester) async {
    final config = ShellConfig(
      title: (_) => 'Context shell',
      destinations: [
        ShellDestination(
          id: 'test',
          title: (_) => 'Test',
          icon: Icons.dashboard_outlined,
          lockedVisible: true,
          builder: (_, _, _, _) => const Scaffold(body: Text('Route content')),
        ),
      ],
      contexts: [
        ShellContext(
          id: 'context-a',
          title: (_) => 'Context A',
          modules: [
            ShellModule(
              id: 'module-a1',
              title: (_) => 'Module A1',
              builder: (_) => const Center(child: Text('Module A1 content')),
            ),
            ShellModule(
              id: 'module-a2',
              title: (_) => 'Module A2',
              builder: (_) => const Center(child: Text('Module A2 content')),
            ),
            ShellModule(
              id: 'module-a3',
              title: (_) => 'Module A3',
              builder: (_) => const Center(child: Text('Module A3 content')),
            ),
          ],
        ),
        ShellContext(
          id: 'context-b',
          title: (_) => 'Context B',
          modules: [
            ShellModule(
              id: 'module-b1',
              title: (_) => 'Module B1',
              builder: (_) => const Center(child: Text('Module B1 content')),
            ),
          ],
        ),
      ],
    );
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(config));
    await tester.pumpAndSettle();
    expect(find.text('Route content'), findsOneWidget);
    await tester.tap(find.byTooltip('Select module'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Module A1').last);
    await tester.pumpAndSettle();
    expect(ic.sl<SettingsController>().settings.selectedModuleId, 'module-a1');
    expect(find.text('Module A1 content'), findsOneWidget);

    await tester.tap(find.byTooltip('Select module'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Module A2'));
    await tester.pumpAndSettle();
    expect(ic.sl<SettingsController>().settings.selectedModuleId, 'module-a2');
    expect(find.text('Module A2 content'), findsOneWidget);

    await tester.tap(find.byTooltip('Select context'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Context B').last);
    await tester.pumpAndSettle();

    final settings = ic.sl<SettingsController>().settings;
    expect(settings.selectedContextId, 'context-b');
    expect(settings.selectedModuleId, 'module-b1');
    expect(find.text('Module B1 content'), findsOneWidget);
    expect(Settings.fromJson(settings.toJson()).selectedContextId, 'context-b');

    tester.view.physicalSize = const Size(720, 900);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Select context'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Context A').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Select module'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Module A3').last);
    await tester.pumpAndSettle();
    expect(ic.sl<SettingsController>().settings.selectedModuleId, 'module-a3');
    expect(find.text('Module A3 content'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('split pane resizes, collapses at compact width and resets', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(_testConfig()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open split view'));
    await tester.pumpAndSettle();
    expect(find.text('Split test content'), findsOneWidget);
    expect(find.byKey(const ValueKey('split-divider')), findsOneWidget);

    await tester.drag(find.byKey(const ValueKey('split-divider')), const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(ic.sl<SettingsController>().settings.splitRatio, greaterThan(0.5));

    tester.view.physicalSize = const Size(720, 900);
    await tester.pumpAndSettle();
    expect(find.text('Split test content'), findsNothing);
    expect(ic.sl<SettingsController>().settings.splitOpen, isTrue);

    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();
    expect(find.text('Split test content'), findsOneWidget);
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore default layout'));
    await tester.pumpAndSettle();
    expect(ic.sl<SettingsController>().settings.splitOpen, isFalse);
    expect(ic.sl<SettingsController>().settings.splitRatio, 0.5);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}

ShellConfig _testConfig() => ShellConfig(
  title: (_) => 'Test shell',
  destinations: [
    ShellDestination(
      id: 'test',
      title: (_) => 'Registered destination',
      icon: Icons.dashboard_outlined,
      lockedVisible: true,
      builder: (_, _, _, _) => const Scaffold(body: Center(child: Text('Registered page'))),
    ),
  ],
  views: [
    ShellViewRegistration(id: 'route', title: (_, _) => 'Current page'),
    ShellViewRegistration(
      id: 'registered-view',
      title: (_, id) => id == 'registered-view' ? 'Registered view' : 'Registered view ${id.split('-').last}',
      builder: (_) => const Center(child: Text('Registered view content')),
      statusProviderFactory: _TestStatusProvider.new,
    ),
  ],
  inspectorBuilder: (_) => const Text('Inspector slot'),
  splitPaneBuilder: (_) => const Center(child: Text('Split test content')),
);

Widget _app(ShellConfig config) => AppScope(
  settings: ic.sl<SettingsController>(),
  services: ic.sl<AppServices>(),
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: HomePage(mainNavigatorKey: GlobalKey<NavigatorState>(), config: config),
  ),
);

class _TestStatusProvider extends ShellStatusProvider {
  final String instanceId;

  _TestStatusProvider(this.instanceId);

  @override
  List<ShellStatusItem> get items => [ShellStatusItem(id: instanceId, label: 'Status $instanceId')];
}
