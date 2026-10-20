import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/core/app_scope.dart';
import 'package:flutter_template/core/app_services.dart';
import 'package:flutter_template/core/injection.dart' as ic;
import 'package:flutter_template/pages/settings/settings_controller.dart';
import 'package:flutter_template/core/themes.dart';
import 'package:flutter_template/l10n/l10n.dart';
import 'package:flutter_template/pages/home/home_page.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';
import 'package:flutter_template/pages/home/default_shell_config.dart';
import 'package:flutter_template/pages/home/shell_navigation_coordinator.dart';
import 'package:flutter_template/pages/home/widgets/shell_status_bar.dart';

import 'support/public_shell_feature.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async => SharedPreferences.setMockInitialValues({}));
  tearDown(() async => ic.sl.reset());

  testWidgets('public feature registrations drive independent tabs and shell contributions', (tester) async {
    await ic.init();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final config = PublicShellFeature.registerWith(defaultShellConfig());
    await tester.pumpWidget(_app(config));
    await tester.pumpAndSettle();
    final home = tester.state<HomePageState>(find.byType(HomePage));
    await home.selectedPage('sample-feature');
    await tester.pumpAndSettle();

    expect(find.text('Dashboard count: 0 · Page: summary'), findsOneWidget);
    expect(find.text('Sample secondary pane'), findsOneWidget);
    expect(find.text('Inspector for sample-dashboard-1'), findsOneWidget);
    expect(find.byType(ShellStatusBar), findsOneWidget);
    expect(find.text('Sample items: 0'), findsOneWidget);
    expect(find.byTooltip('Add sample item'), findsOneWidget);

    Future<void> openBreadcrumbMenu() async {
      final root = find.byKey(const ValueKey('breadcrumb-node-sample-feature-root:sample-dashboard-1'));
      if (root.evaluate().isEmpty) {
        await tester.tap(find.byKey(const ValueKey('breadcrumb-overflow')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sample workspace').last);
        await tester.pumpAndSettle();
      }
      await tester.tap(root);
      await tester.pumpAndSettle();
    }

    await openBreadcrumbMenu();
    await tester.tap(find.text('Activity').last);
    await tester.pumpAndSettle();
    expect(find.text('Dashboard count: 0 · Page: activity'), findsOneWidget);
    await openBreadcrumbMenu();
    await tester.tap(find.text('Summary').last);
    await tester.pumpAndSettle();
    expect(find.text('Dashboard count: 0 · Page: summary'), findsOneWidget);

    await tester.tap(find.byTooltip('Add sample item'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard count: 1 · Page: summary'), findsOneWidget);
    expect(find.text('Sample items: 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sample-note-a')));
    await tester.pumpAndSettle();
    expect(find.text('Document note-a'), findsOneWidget);
    await tester.tap(find.text('Increment document'));
    await tester.pumpAndSettle();
    expect(find.text('Document count: 1'), findsOneWidget);

    home.openView('sample-dashboard', sectionId: 'sample-feature');
    await tester.pumpAndSettle();
    expect(find.text('Dashboard count: 1 · Page: summary'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sample-note-b')));
    await tester.pumpAndSettle();
    expect(find.text('Document note-b'), findsOneWidget);
    expect(find.text('Document count: 0'), findsOneWidget);
    home.openView('sample-document', sectionId: 'sample-feature', instanceId: 'note-a');
    await tester.pumpAndSettle();
    expect(find.text('Document count: 1'), findsOneWidget);
    home.openView('sample-document', sectionId: 'sample-feature', instanceId: 'note-b');
    await tester.pumpAndSettle();
    expect(find.text('Document count: 0'), findsOneWidget);

    final saved = ic.sl<SettingsController>().settings.shellWorkspaces;
    expect(saved.singleWhere((workspace) => workspace.sectionId == 'sample-feature').tabs, hasLength(3));
    home.openView('sample-dashboard', sectionId: 'sample-feature');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sample-cross-section')));
    await tester.pumpAndSettle();
    expect(home.currentDestinationId, 'page2');
    await home.selectedPage('sample-feature');
    await tester.pumpAndSettle();
    expect(find.text('Dashboard count: 1 · Page: summary'), findsOneWidget);

    await tester.pumpWidget(_app(config, homeKey: const ValueKey('restored-shell')));
    await tester.pumpAndSettle();
    final restoredHome = tester.state<HomePageState>(find.byType(HomePage));
    expect(restoredHome.currentDestinationId, 'sample-feature');
    expect(
      ic
          .sl<SettingsController>()
          .settings
          .shellWorkspaces
          .singleWhere((workspace) => workspace.sectionId == 'sample-feature')
          .tabs,
      hasLength(3),
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  test('registrations cannot be removed until feature tabs are closed', () {
    final section = ShellDestination(
      id: 'sample-feature',
      title: (_) => 'Sample feature',
      icon: Icons.extension_outlined,
      defaultViewId: 'sample-dashboard',
      allowedViewIds: const {'sample-dashboard'},
    );
    final view = ShellViewRegistration(
      id: 'sample-dashboard',
      title: (_, _) => 'Sample dashboard',
      destinationId: 'sample-feature',
      viewBuilder: (_, _) => const SizedBox.shrink(),
    );
    final navigation = ShellNavigationCoordinator(sections: [section], views: [view]);
    final tabId = navigation.openTab('sample-feature', 'sample-dashboard')!;

    expect(navigation.unregisterView('sample-dashboard'), isFalse);
    expect(navigation.unregisterSection('sample-feature'), isFalse);
    navigation.closeTab('sample-feature', tabId, closable: true);
    expect(navigation.unregisterView('sample-dashboard'), isTrue);
    expect(navigation.unregisterSection('sample-feature'), isTrue);
    navigation.dispose();
  });
}

Widget _app(ShellConfig config, {Key? homeKey}) => AppScope(
  settings: ic.sl<SettingsController>(),
  services: ic.sl<AppServices>(),
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.dark(),
    home: HomePage(key: homeKey, mainNavigatorKey: GlobalKey<NavigatorState>(), config: config),
  ),
);
