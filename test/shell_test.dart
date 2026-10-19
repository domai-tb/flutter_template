import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/core/app_scope.dart';
import 'package:flutter_template/core/app_services.dart';
import 'package:flutter_template/core/injection.dart' as ic;
import 'package:flutter_template/core/settings.dart';
import 'package:flutter_template/core/shell_notifications.dart';
import 'package:flutter_template/core/themes.dart';
import 'package:flutter_template/l10n/l10n.dart';
import 'package:flutter_template/pages/home/home_page.dart';
import 'package:flutter_template/pages/home/widgets/bottom_nav_bar.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';
import 'package:flutter_template/pages/page6/page6_settings_page.dart';
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

  testWidgets('deep links open registered tabs without changing the selected activity', (tester) async {
    final settings = ic.sl<SettingsController>();
    settings.update(
      settings.settings.copyWith(
        shellTabs: const [ShellTabPreference(id: 'page1', registrationId: 'page1', destinationId: 'page1')],
        selectedShellTabId: 'page1',
      ),
    );

    await tester.pumpWidget(_app(null, routeInformation: RouteInformation(uri: Uri.parse('/page2'))));
    await tester.pumpAndSettle();

    expect(tester.state<HomePageState>(find.byType(HomePage)).currentDestinationId, 'page1');
    expect(settings.settings.selectedShellTabId, 'page2-1');
    expect(settings.settings.shellTabs.map((tab) => tab.registrationId), ['page1', 'page2']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('desktop footer stays visible and pinned with empty status providers', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(_testConfig()));
    for (final size in [
      const Size(390, 844),
      const Size(720, 900),
      const Size(960, 700),
      const Size(1280, 720),
      const Size(1440, 900),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      final footer = find.byKey(const ValueKey('shell-status-bar'));
      expect(footer, findsOneWidget);
      expect(tester.getSize(footer).height, 24);
      expect(tester.getRect(footer).bottom, size.height);
      expect(find.text('Desktop'), findsNothing);
      expect(find.text('Ready'), findsNothing);
      expect(find.byType(BottomNavBar), findsNothing);
      if (size.width <= 720) expect(find.byType(ReorderableListView), findsOneWidget);
    }
    await tester.tap(find.byTooltip('Open inspector'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey('shell-status-bar'))).bottom, 900);
    tester.view.physicalSize = const Size(720, 900);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey('shell-status-bar'))).bottom, 900);
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey('shell-status-bar'))).bottom, 900);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('touch navigation hides the desktop footer', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(_testConfig()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('shell-status-bar')), findsNothing);
    expect(find.byType(BottomNavBar), findsOneWidget);
    expect(find.byType(ReorderableListView), findsNothing);
    expect(tester.getSize(find.byKey(const ValueKey('header-action-notifications'))), const Size(48, 48));
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('desktop header actions use aligned 32dp cells', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(_testConfig()));

    const ids = ['inspector', 'notifications', 'search', 'more'];
    const icons = [Icons.vertical_split, Icons.notifications_none, Icons.search, Icons.more_vert];
    for (final size in [const Size(720, 900), const Size(1280, 720), const Size(1440, 900)]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      final cells = [for (final id in ids) find.byKey(ValueKey('header-action-$id'))];
      final cellRects = cells.map(tester.getRect).toList();
      final iconRects = [
        for (var index = 0; index < cells.length; index++)
          tester.getRect(find.descendant(of: cells[index], matching: find.byIcon(icons[index]))),
      ];

      for (final rect in cellRects) {
        expect(rect.size, const Size(32, 32));
      }
      for (var index = 0; index < cells.length - 1; index++) {
        expect(cellRects[index + 1].center.dx - cellRects[index].center.dx, closeTo(36, 2));
        expect(iconRects[index].center.dy, closeTo(iconRects[index + 1].center.dy, 1));
      }
      expect(size.width - cellRects.last.right, closeTo(8, 1));
      expect(find.byKey(const ValueKey('header-action-notifications')), findsOneWidget);
      expect(find.byKey(const ValueKey('header-action-search')), findsOneWidget);
      expect(find.byKey(const ValueKey('header-action-more')), findsOneWidget);
      expect(find.byTooltip('Find open tab'), findsOneWidget);
      expect(find.byTooltip('Open view'), findsOneWidget);
      if (size.width == 720) {
        expect(find.byTooltip('Navigation'), findsOneWidget);
        expect(find.byKey(const ValueKey('shell-status-bar')), findsOneWidget);
      }

      final tabOverflow = tester.getRect(find.byKey(const ValueKey('tab-overflow-action')));
      final tabAdd = tester.getRect(find.byKey(const ValueKey('tab-add-action')));
      expect(tabOverflow.size, const Size(32, 32));
      expect(tabAdd.size, const Size(32, 32));
      expect(tabAdd.center.dx - tabOverflow.center.dx, closeTo(36, 2));
      expect(size.width - tabAdd.right, closeTo(8, 1));

      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();
      final menuItems = find.byType(PopupMenuItem<String>);
      expect(menuItems, findsAtLeastNWidgets(1));
      expect(tester.getSize(menuItems.first).height, inInclusiveRange(28, 34));
      await tester.tapAt(Offset(size.width / 2, size.height / 2));
      await tester.pumpAndSettle();
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('comfortable desktop header and tab actions use 36dp cells', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = ic.sl<SettingsController>();
    settings.update(settings.settings.copyWith(density: 'comfortable'));

    await tester.pumpWidget(_app(_testConfig()));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byKey(const ValueKey('header-action-notifications'))), const Size(36, 36));
    final tabOverflow = tester.getRect(find.byKey(const ValueKey('tab-overflow-action')));
    final tabAdd = tester.getRect(find.byKey(const ValueKey('tab-add-action')));
    expect(tabOverflow.size, const Size(36, 36));
    expect(tabAdd.size, const Size(36, 36));
    expect(tabAdd.center.dx - tabOverflow.center.dx, closeTo(40, 2));

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PopupMenuItem<String>).first).height, inInclusiveRange(34, 38));
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('desktop rail keeps aligned icons and hover does not navigate', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(null));
    await tester.pumpAndSettle();
    final home = tester.state<HomePageState>(find.byType(HomePage));
    const ids = ['page1', 'page2', 'page3', 'page4', 'page5', 'page6'];
    expect(tester.getSize(find.byKey(const ValueKey('activity-rail'))).width, 48);
    final rows = [for (final id in ids) find.byKey(ValueKey('activity-rail-$id'))];
    final rowRects = rows.map(tester.getRect).toList();
    final iconRects = [for (final row in rows) tester.getRect(find.descendant(of: row, matching: find.byType(Icon)))];

    for (final rect in rowRects) {
      expect(rect.height, 44);
    }
    expect(iconRects.map((rect) => rect.center.dx).toSet().length, 1);
    expect(tester.getSize(find.byKey(const ValueKey('activity-rail-indicator-page1'))), const Size(3, 16));

    await tester.sendEventToBinding(PointerHoverEvent(position: rowRects[1].center));
    await tester.pump();
    expect(home.currentDestinationId, 'page1');

    await tester.tap(find.descendant(of: rows[1], matching: find.byType(InkWell)));
    await tester.pump();
    expect(home.currentDestinationId, 'page2');
    expect(find.byKey(const ValueKey('activity-rail-indicator-page2')), findsOneWidget);
    final selectedModuleId = ic.sl<SettingsController>().settings.selectedModuleId;
    await tester.tap(rows[5]);
    await tester.pump();
    expect(home.currentDestinationId, 'page6');
    expect(ic.sl<SettingsController>().settings.selectedModuleId, selectedModuleId);
    expect(find.byKey(const ValueKey('activity-rail-indicator-page6')), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('desktop Settings uses horizontal compact sections and a narrow selector', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_settingsApp());

    for (final size in [const Size(1280, 720), const Size(1440, 900)]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      final navigation = find.byKey(const ValueKey('settings-section-navigation'));
      await tester.tap(find.byKey(const ValueKey('settings-section-0')));
      await tester.pumpAndSettle();
      expect(tester.getSize(navigation).width, 184);
      expect(tester.getSize(find.byKey(const ValueKey('settings-form'))).width, lessThanOrEqualTo(560));
      expect(tester.getSize(find.byType(AppSegmentedTripleControl)).height, inInclusiveRange(28, 32));
      expect(tester.getSize(find.byType(DropdownButtonFormField<String>).first).height, inInclusiveRange(28, 32));
      expect(tester.getSize(find.widgetWithText(TextButton, 'Reset appearance')).height, inInclusiveRange(28, 32));
      for (var index = 0; index < 6; index++) {
        final row = find.byKey(ValueKey('settings-section-$index'));
        expect(tester.getSize(row).height, 32);
        final icon = tester.getRect(find.descendant(of: row, matching: find.byType(Icon)));
        final title = tester.getRect(find.descendant(of: row, matching: find.byType(Text)));
        expect(icon.right, lessThan(title.left));
        expect(icon.center.dy, closeTo(title.center.dy, 1));
      }

      final layoutRow = find.byKey(const ValueKey('settings-section-1'));
      await tester.sendEventToBinding(PointerHoverEvent(position: tester.getCenter(layoutRow)));
      await tester.pump();
      expect(find.text('Spacing'), findsNothing);
      await tester.sendEventToBinding(const PointerHoverEvent(position: Offset(500, 500)));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: layoutRow, matching: find.byType(InkWell)));
      await tester.pumpAndSettle();
      expect(find.text('Spacing'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('settings-section-0')));
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Spacing'), findsWidgets);
    }

    tester.view.physicalSize = const Size(720, 900);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-section-selector')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-section-navigation')), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('phone Settings keeps sections in one scrolling column', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_settingsApp());
    await tester.pumpAndSettle();

    expect(find.byType(ExpansionTile), findsNWidgets(6));
    expect(find.byKey(const ValueKey('settings-section-navigation')), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Settings section navigation expands for large text', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_settingsApp(textScale: 2));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byKey(const ValueKey('settings-section-0'))).height, 64);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('comfortable Settings uses comfortable row and control sizes', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ic.sl<SettingsController>().update(ic.sl<SettingsController>().settings.copyWith(density: 'comfortable'));

    await tester.pumpWidget(_settingsApp());
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byKey(const ValueKey('settings-section-0'))).height, 36);
    expect(tester.getSize(find.byType(AppSegmentedTripleControl)).height, inInclusiveRange(34, 38));
    expect(tester.getSize(find.byType(DropdownButtonFormField<String>).first).height, inInclusiveRange(34, 38));
    expect(tester.getSize(find.widgetWithText(TextButton, 'Reset appearance')).height, inInclusiveRange(34, 38));
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('registered views open independently from activities and contribute tab status', (tester) async {
    final providers = <String, _TestStatusProvider>{};
    final config = _testConfig(providers: providers);
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settings = ic.sl<SettingsController>();
    await tester.pumpWidget(_app(config));
    await tester.pumpAndSettle();

    final footer = find.byKey(const ValueKey('shell-status-bar'));
    expect(footer, findsOneWidget);
    expect(tester.getRect(footer).bottom, 900);
    expect(find.text('No views are open.'), findsOneWidget);
    expect(find.text('Ready'), findsNothing);

    final home = tester.state<HomePageState>(find.byType(HomePage));
    final activityId = home.currentDestinationId;
    final testTabId = home.openView('test');
    await tester.pumpAndSettle();
    expect(testTabId, 'test-1');
    expect(find.text('Registered page'), findsOneWidget);
    expect(home.currentDestinationId, activityId);

    await home.selectedPage('test');
    await home.selectedPage('test');
    await tester.pumpAndSettle();
    expect(settings.settings.selectedShellTabId, testTabId);
    expect(settings.settings.shellTabs.map((tab) => tab.id), ['test-1']);

    await tester.tap(find.byTooltip('Open view'));
    await tester.pumpAndSettle();
    expect(find.text('Registered view'), findsWidgets);
    await tester.tap(find.text('Registered view').last);
    await tester.pumpAndSettle();
    expect(find.text('Registered view content'), findsOneWidget);
    expect(find.text('Status registered-view-1'), findsOneWidget);
    expect(find.descendant(of: footer, matching: find.text('Status registered-view-1')), findsOneWidget);
    providers['registered-view-1']!.update('Status updated view A');
    await tester.pump();
    expect(find.descendant(of: footer, matching: find.text('Status updated view A')), findsOneWidget);
    providers['registered-view-1']!.update('Status registered-view-1');
    await tester.pump();

    await home.selectedPage('test');
    await tester.pumpAndSettle();
    expect(footer, findsOneWidget);
    expect(find.text('Status registered-view-1'), findsOneWidget);
    await tester.tap(find.byTooltip('Open view'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registered view').last);
    await tester.pumpAndSettle();
    expect(find.text('Status registered-view-2'), findsOneWidget);
    await tester.tap(find.text('Registered view 1'));
    await tester.pumpAndSettle();
    expect(find.text('Status registered-view-1'), findsOneWidget);
    expect(settings.settings.shellTabs.map((tab) => tab.id), ['test-1', 'registered-view-1', 'registered-view-2']);

    await tester.tap(find.byTooltip('Close').last);
    await tester.pumpAndSettle();
    expect(providers['registered-view-1']!.disposed, isTrue);
    expect(settings.settings.shellTabs.map((tab) => tab.id), ['test-1', 'registered-view-2']);
    expect(find.text('Status registered-view-1'), findsNothing);
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
    final popover = tester.getRect(find.byKey(const ValueKey('notifications-popover')));
    final notificationButton = tester.getRect(find.byTooltip('Open notifications'));
    expect(popover.size, const Size(360, 400));
    expect(popover.top, greaterThanOrEqualTo(notificationButton.bottom));
    expect(popover.right, lessThanOrEqualTo(1440));
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
      tester.state<HomePageState>(find.byType(HomePage)).openView('test');
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
          destinations: const [],
          views: [
            ShellViewRegistration(
              id: 'broken',
              title: (_, _) => 'Broken',
              viewBuilder: (_, _) => throw StateError('intentional'),
            ),
          ],
        ),
      ),
    );
    tester.state<HomePageState>(find.byType(HomePage)).openView('broken');
    await tester.pumpAndSettle();
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
        ShellDestination(id: 'test', title: (_) => 'Test', icon: Icons.dashboard_outlined, lockedVisible: true),
      ],
      views: [
        ShellViewRegistration(
          id: 'start',
          title: (_, _) => 'Start view',
          viewBuilder: (_, _) => const Scaffold(body: Text('Route content')),
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
    ic.sl<SettingsController>().update(ic.sl<SettingsController>().settings.copyWith(selectedContextId: 'context-a'));

    await tester.pumpWidget(_app(config));
    await tester.pumpAndSettle();
    tester.state<HomePageState>(find.byType(HomePage)).openView('start');
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

    expect(find.text('Module A2 content'), findsOneWidget);
    expect(ic.sl<SettingsController>().settings.selectedModuleId, isNull);
    await tester.tap(find.byTooltip('Select module'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Module B1'));
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

ShellConfig _testConfig({Map<String, _TestStatusProvider>? providers}) => ShellConfig(
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
      id: 'start',
      title: (_, _) => 'Start view',
      viewBuilder: (_, _) => const Scaffold(body: Text('Route content')),
    ),
    ShellViewRegistration(
      id: 'test',
      title: (_, _) => 'Registered destination',
      viewBuilder: (_, _) => const Scaffold(body: Center(child: Text('Registered page'))),
      statusProviderFactory: (_) => _EmptyStatusProvider(),
    ),
    ShellViewRegistration(
      id: 'registered-view',
      title: (_, id) => id == 'registered-view' ? 'Registered view' : 'Registered view ${id.split('-').last}',
      viewBuilder: (_, _) => const Center(child: Text('Registered view content')),
      statusProviderFactory: (id) {
        final provider = _TestStatusProvider(id);
        providers?[id] = provider;
        return provider;
      },
    ),
  ],
  inspectorBuilder: (_) => const Text('Inspector slot'),
  splitPaneBuilder: (_) => const Center(child: Text('Split test content')),
);

Widget _app(ShellConfig? config, {RouteInformation? routeInformation}) {
  final settings = ic.sl<SettingsController>();
  return AppScope(
    settings: settings,
    services: ic.sl<AppServices>(),
    child: AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final value = settings.settings;
        final themeMode = value.useSystemDarkmode
            ? ThemeMode.system
            : value.useDarkmode
            ? ThemeMode.dark
            : ThemeMode.light;
        return MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(accentPreset: value.accentPreset, comfortable: value.density == 'comfortable'),
          darkTheme: AppTheme.dark(accentPreset: value.accentPreset, comfortable: value.density == 'comfortable'),
          themeMode: themeMode,
          home: HomePage(
            mainNavigatorKey: GlobalKey<NavigatorState>(),
            config: config,
            routeInformation: routeInformation,
          ),
        );
      },
    ),
  );
}

Widget _settingsApp({double textScale = 1}) {
  final settings = ic.sl<SettingsController>();
  return AppScope(
    settings: settings,
    services: ic.sl<AppServices>(),
    child: AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final value = settings.settings;
        final themeMode = value.useSystemDarkmode
            ? ThemeMode.system
            : value.useDarkmode
            ? ThemeMode.dark
            : ThemeMode.light;
        return MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(accentPreset: value.accentPreset, comfortable: value.density == 'comfortable'),
          darkTheme: AppTheme.dark(accentPreset: value.accentPreset, comfortable: value.density == 'comfortable'),
          themeMode: themeMode,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
              child: const Page6SettingsPage(),
            ),
          ),
        );
      },
    ),
  );
}

class _EmptyStatusProvider extends ShellStatusProvider {
  @override
  List<ShellStatusItem> get items => const [];
}

class _TestStatusProvider extends ShellStatusProvider {
  final String instanceId;
  late String _label = 'Status $instanceId';
  bool disposed = false;

  _TestStatusProvider(this.instanceId);

  @override
  List<ShellStatusItem> get items => [ShellStatusItem(id: instanceId, label: _label)];

  void update(String label) {
    _label = label;
    notifyListeners();
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}
