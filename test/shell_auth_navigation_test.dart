import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/core/app_scope.dart';
import 'package:flutter_template/core/app_services.dart';
import 'package:flutter_template/core/injection.dart' as ic;
import 'package:flutter_template/core/shell_auth.dart';
import 'package:flutter_template/core/themes.dart';
import 'package:flutter_template/l10n/l10n.dart';
import 'package:flutter_template/pages/home/home_page.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';
import 'package:flutter_template/pages/home/widgets/bottom_nav_bar.dart';
import 'package:flutter_template/pages/home/widgets/shell_status_bar.dart';
import 'package:flutter_template/pages/settings/settings_controller.dart';
import 'package:flutter_template/pages/settings/settings_entity.dart';
import 'package:flutter_template/pages/settings/settings_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async => SharedPreferences.setMockInitialValues({}));
  tearDown(() async => ic.sl.reset());

  testWidgets('guest account opens an honest unavailable login template', (tester) async {
    await ic.init();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('header-action-account')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('activity-rail-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Guest · Not signed in'), findsOneWidget);
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Sign-in is not configured'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Return to app'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('desktop toolbar, rail, tabs, and status bar follow shared geometry', (tester) async {
    await ic.init();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(config: _config(sections: 5)));
    await tester.pumpAndSettle();

    final sidebar = tester.getRect(find.byKey(const ValueKey('header-action-right-sidebar')));
    final palette = tester.getRect(find.byKey(const ValueKey('header-action-command-palette')));
    final search = tester.getRect(find.byKey(const ValueKey('header-action-search-tabs')));
    expect(search.size, const Size.square(32));
    expect(palette.size, search.size);
    expect(sidebar.size, search.size);
    expect(search.center.dy, palette.center.dy);
    expect(palette.center.dy, sidebar.center.dy);
    expect(palette.left, greaterThan(sidebar.right));
    expect(search.left, greaterThan(palette.right));

    final rail = tester.getRect(find.byKey(const ValueKey('activity-rail')));
    final settings = tester.getRect(find.byKey(const ValueKey('activity-rail-settings')));
    final tabStrip = tester.getRect(find.byType(ReorderableListView).first);
    final status = tester.getRect(find.byType(ShellStatusBar));
    expect(rail.top, 48);
    expect(status.top - rail.bottom, 8);
    expect(settings.bottom, closeTo(rail.bottom, 1));
    expect(settings.height, 44);
    expect(tabStrip.left - rail.right, closeTo(8, 1));
    expect(tabStrip.height, 34);
    expect(status.height, 24);
    expect(1440 - tester.getRect(find.byKey(const ValueKey('status-notifications'))).right, lessThanOrEqualTo(8));
    expect(find.byKey(const ValueKey('header-action-notifications')), findsNothing);
    expect(find.byKey(const ValueKey('status-notifications')), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('phone-sized desktop windows keep the compact rail instead of mobile navigation', (tester) async {
    await ic.init();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('activity-rail')), findsOneWidget);
    expect(find.byType(BottomNavBar), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('configured provider updates avatar, profile, and signed-out state', (tester) async {
    final auth = _TestAuthProvider();
    addTearDown(auth.dispose);
    await ic.init(authProvider: auth);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final home = tester.state<HomePageState>(find.byType(HomePage));
    expect(auth.restoreCalls, 1);
    await tester.tap(find.byKey(const ValueKey('activity-rail-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    EditableText editable(int index) =>
        tester.widget<EditableText>(find.descendant(of: fields.at(index), matching: find.byType(EditableText)));
    expect(editable(0).autofillHints, contains(AutofillHints.username));
    expect(editable(1).autofillHints, contains(AutofillHints.password));
    expect(editable(0).textInputAction, TextInputAction.next);
    expect(editable(1).textInputAction, TextInputAction.done);
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    expect(find.text('This field is required.').first, findsOneWidget);
    expect(auth.lastEmail, isNull);
    await tester.enterText(find.byType(TextFormField).at(0), 'ada@example.test');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(1), 'never-persist-this');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    expect(auth.lastEmail, 'ada@example.test');
    expect(find.text('AL'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('app_settings_json_v1') ?? '', isNot(contains('never-persist-this')));

    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('ada@example.test'), findsWidgets);
    expect(find.text('acct-42'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(auth.state.value.status, ShellAuthStatus.signedOut);
    expect(find.text('Guest · Not signed in'), findsOneWidget);
    await home.selectedPage('section-0');
    await tester.pumpAndSettle();
    expect(find.text('AL'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('desktop Settings stays pinned, is canonical, and restores the active workspace tab', (tester) async {
    await ic.init();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(760, 560);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ic.sl<SettingsController>().update(
      ic.sl<SettingsController>().settings.copyWith(
        navBarItemOrder: const ['settings', 'section-3', 'section-2'],
        hiddenNavBarItems: const ['settings'],
      ),
    );

    await tester.pumpWidget(_app(config: _config(sections: 14)));
    await tester.pumpAndSettle();
    final rail = find.byKey(const ValueKey('activity-rail'));
    final settingsItem = find.byKey(const ValueKey('activity-rail-settings'));
    final pinnedRect = tester.getRect(settingsItem);
    expect(tester.getRect(rail).bottom - pinnedRect.bottom, lessThanOrEqualTo(7));
    await tester.drag(find.byKey(const ValueKey('activity-rail-sections')), const Offset(0, -420));
    await tester.pumpAndSettle();
    expect(tester.getRect(settingsItem).top, pinnedRect.top);

    final home = tester.state<HomePageState>(find.byType(HomePage));
    final localizations = AppLocalizations.of(tester.element(find.byType(HomePage)))!;
    final tabId = home.openView('details', sectionId: 'section-0')!;
    await tester.pumpAndSettle();
    await tester.tap(settingsItem);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(_workspace('settings').tabs, hasLength(1));
    expect(_workspace('settings').tabs.single.registrationId, 'settings');
    expect(ic.sl<SettingsController>().settings.hiddenNavBarItems, contains('settings'));

    await tester.tap(settingsItem);
    await tester.pumpAndSettle();
    expect(_workspace('settings').tabs, hasLength(1));
    await tester.tap(find.byTooltip('Return to previous section'));
    await tester.pumpAndSettle();
    expect(home.currentDestinationId, 'section-0');
    expect(_workspace('section-0').activeTabId, tabId);

    Focus.of(tester.element(find.byType(AnnotatedRegion<SystemUiOverlayStyle>))).requestFocus();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    await tester.tap(find.text(localizations.openSettings));
    await tester.pumpAndSettle();
    expect(home.currentDestinationId, 'settings');
    expect(_workspace('settings').tabs, hasLength(1));
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('mobile uses a bottom scroller with Profile and selected Settings', (tester) async {
    await ic.init();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(config: _config(sections: 10)));
    await tester.pumpAndSettle();
    final home = tester.state<HomePageState>(find.byType(HomePage));
    await home.selectedPage('settings');
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavBar), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-rail')), findsNothing);
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.byKey(const ValueKey('header-action-account')), findsNothing);
    expect(find.byKey(const ValueKey('bottom-navigation-item-profile')), findsOneWidget);
    final bar = tester.getRect(find.byType(BottomNavBar));
    final settingsItem = tester.getRect(find.byKey(const ValueKey('bottom-navigation-item-settings')));
    expect(bar.bottom, lessThanOrEqualTo(844));
    expect(844 - bar.bottom, lessThanOrEqualTo(10));
    expect(settingsItem.left, greaterThanOrEqualTo(bar.left));
    expect(settingsItem.right, lessThanOrEqualTo(bar.right));
    expect(_workspace('settings').tabs.single.registrationId, 'settings');
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('legacy Settings preference migrates into the dedicated workspace', (tester) async {
    await ic.init();
    final controller = ic.sl<SettingsController>();
    controller.update(
      controller.settings.copyWith(
        shellTabs: const [
          ShellTabPreference(
            id: 'page6::settings::1',
            sectionId: 'page6',
            registrationId: 'settings',
            instanceId: 'settings-1',
            destinationId: 'page6',
          ),
        ],
        selectedShellTabId: 'page6::settings::1',
        selectedActivityId: 'page6',
      ),
    );
    await tester.pumpWidget(_app(config: _config()));
    await tester.pumpAndSettle();
    final home = tester.state<HomePageState>(find.byType(HomePage));
    expect(home.currentDestinationId, 'settings');
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(_workspace('settings').tabs.single.registrationId, 'settings');
    expect(
      ic
          .sl<SettingsController>()
          .settings
          .shellWorkspaces
          .where((workspace) => workspace.sectionId != 'settings')
          .expand((workspace) => workspace.tabs)
          .where((tab) => tab.registrationId == 'settings'),
      isEmpty,
    );
  });
}

ShellWorkspacePreference _workspace(String id) =>
    ic.sl<SettingsController>().settings.shellWorkspaces.singleWhere((workspace) => workspace.sectionId == id);

Widget _app({ShellConfig? config}) => AppScope(
  settings: ic.sl<SettingsController>(),
  services: ic.sl<AppServices>(),
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.dark(),
    home: HomePage(mainNavigatorKey: GlobalKey<NavigatorState>(), config: config ?? _config()),
  ),
);

ShellConfig _config({int sections = 1}) => ShellConfig(
  title: (_) => 'Test application',
  destinations: [
    for (var index = 0; index < sections; index++)
      ShellDestination(
        id: 'section-$index',
        title: (_) => 'Section $index',
        icon: Icons.dashboard_outlined,
        defaultViewId: 'section-$index',
        allowedViewIds: {'section-$index', 'details'},
      ),
  ],
  views: [
    for (var index = 0; index < sections; index++)
      ShellViewRegistration(
        id: 'section-$index',
        destinationId: 'section-$index',
        title: (_, _) => 'Section view',
        reusePolicy: ShellViewReusePolicy.byRegistration,
        viewBuilder: (_, _) => Center(child: Text('Workspace $index')),
      ),
    ShellViewRegistration(
      id: 'details',
      title: (_, _) => 'Details',
      reusePolicy: ShellViewReusePolicy.byRegistration,
      viewBuilder: (_, _) => const Center(child: Text('Details view')),
    ),
  ],
);

class _TestAuthProvider extends ShellAuthProvider {
  final ValueNotifier<ShellAuthState> _state = ValueNotifier(const ShellAuthState(status: ShellAuthStatus.signedOut));
  String? lastEmail;
  int restoreCalls = 0;

  @override
  ValueListenable<ShellAuthState> get state => _state;

  @override
  Future<void> restoreSession() async => restoreCalls++;

  @override
  Future<ShellAuthResult> signIn({required String email, required String password}) async {
    lastEmail = email;
    _state.value = const ShellAuthState(
      status: ShellAuthStatus.authenticated,
      user: ShellAuthUser(
        id: 'user-7',
        displayName: 'Ada Lovelace',
        email: 'ada@example.test',
        accountId: 'acct-42',
        providerName: 'Test identity',
      ),
    );
    return const ShellAuthResult.success();
  }

  @override
  Future<void> signOut() async {
    _state.value = const ShellAuthState(status: ShellAuthStatus.signedOut);
  }

  void dispose() => _state.dispose();
}
