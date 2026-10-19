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

  testWidgets('views open independently, retain state, and close in isolation', (tester) async {
    await _pumpShell(tester);
    final home = tester.state<HomePageState>(find.byType(HomePage));

    final first = home.openView('editor', instanceId: 'one', parameters: {'document': 'alpha'});
    final second = home.openView('editor', instanceId: 'two', parameters: {'document': 'beta'});
    await tester.pumpAndSettle();
    expect(first, 'editor-1');
    expect(second, 'editor-2');
    expect(find.text('Document beta'), findsOneWidget);
    expect(home.openView('editor', instanceId: 'one'), first);
    await tester.pump();
    expect(find.text('Document alpha'), findsOneWidget);
    expect(home.openView('editor', instanceId: 'two'), second);
    await tester.pump();
    expect(find.text('Document beta'), findsOneWidget);

    await tester.tap(find.text('Open help from editor'));
    await tester.pumpAndSettle();
    expect(find.text('Help view'), findsOneWidget);
    expect(home.openView('help'), 'help-1');
    await tester.pump();
    expect(ic.sl<SettingsController>().settings.shellTabs, hasLength(3));
    expect(home.currentDestinationId, 'activity-a');

    await tester.tap(find.byTooltip('Editor one'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('increment-one')));
    await tester.tap(find.byKey(const ValueKey('increment-one')));
    await tester.tap(find.byTooltip('Editor two'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('increment-two')));

    await home.selectedPage('activity-b');
    await tester.pumpAndSettle();
    expect(home.currentDestinationId, 'activity-b');
    expect(ic.sl<SettingsController>().settings.selectedShellTabId, second);
    expect(find.text('Document beta'), findsOneWidget);
    expect(find.text('Count: 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Editor one'));
    await tester.pumpAndSettle();
    expect(find.text('Document alpha'), findsOneWidget);
    expect(find.text('Count: 2'), findsOneWidget);

    final secondTab = tester.getCenter(find.byTooltip('Editor two'));
    tester.binding.handlePointerEvent(
      PointerDownEvent(pointer: 42, kind: PointerDeviceKind.mouse, position: secondTab, buttons: kMiddleMouseButton),
    );
    tester.binding.handlePointerEvent(PointerUpEvent(pointer: 42, kind: PointerDeviceKind.mouse, position: secondTab));
    await tester.pumpAndSettle();
    expect(ic.sl<SettingsController>().settings.shellTabs.map((tab) => tab.id), ['editor-1', 'help-1']);
    expect(find.text('Document alpha'), findsOneWidget);
    expect(find.text('Count: 2'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('workspace reordering and keyboard tab actions survive an application restart', (tester) async {
    final config = _config();
    await _pumpShell(tester, config: config);
    final home = tester.state<HomePageState>(find.byType(HomePage));
    home.openView('editor', instanceId: 'one', parameters: {'document': 'alpha'});
    await tester.pump();
    home.openView('editor', instanceId: 'two', parameters: {'document': 'beta'});
    await tester.pump();
    home.openView('help');
    await tester.pump();

    ShellWorkspace.of(tester.element(find.text('Help view'))).reorder(2, 1);
    await tester.pump();
    expect(ic.sl<SettingsController>().settings.shellTabs.map((tab) => tab.id), ['editor-1', 'help-1', 'editor-2']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final restoredSettings = await SettingsController.load();
    addTearDown(restoredSettings.dispose);
    expect(restoredSettings.settings.shellTabs.map((tab) => tab.id), ['editor-1', 'help-1', 'editor-2']);

    await tester.pumpWidget(_app(config, settings: restoredSettings));
    await tester.pump(const Duration(milliseconds: 100));
    expect(restoredSettings.settings.selectedShellTabId, 'help-1');
    expect(find.text('Help view'), findsOneWidget);
    Focus.of(tester.element(find.byType(AnnotatedRegion<SystemUiOverlayStyle>))).requestFocus();
    await tester.pump();
    await tester.tap(find.byTooltip('Editor one'));
    await tester.pump();
    expect(find.text('Document alpha'), findsOneWidget);
    expect(find.text('Restored: true'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(restoredSettings.settings.selectedShellTabId, 'help-1');

    expect(FocusManager.instance.primaryFocus?.context?.widget, isNot(isA<EditableText>()));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(restoredSettings.settings.shellTabs.map((tab) => tab.id), ['editor-1', 'editor-2']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('unavailable restored views remain isolated from registered tabs', (tester) async {
    final settings = ic.sl<SettingsController>();
    settings.update(
      settings.settings.copyWith(
        shellTabs: const [
          ShellTabPreference(id: 'missing-1', registrationId: 'removed-plugin-view'),
          ShellTabPreference(
            id: 'editor-1',
            registrationId: 'editor',
            instanceId: 'saved',
            parameters: {'document': 'saved'},
          ),
        ],
        selectedShellTabId: 'missing-1',
      ),
    );
    await _pumpShell(tester);

    final unavailable = tester.widget<ShellContentSlot>(find.byType(ShellContentSlot));
    expect(unavailable.state, ShellSlotState.unavailable);
    expect(settings.settings.shellTabs, hasLength(2));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Editor saved'));
    await tester.pumpAndSettle();
    expect(find.text('Document saved'), findsOneWidget);
    expect(settings.settings.shellTabs.map((tab) => tab.id), ['missing-1', 'editor-1']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('command palette, toolbar, inspector, and status follow the active view', (tester) async {
    final actions = <String>[];
    final providers = <String, _WorkspaceStatusProvider>{};
    final config = _config(onAction: actions.add, providers: providers);
    await _pumpShell(tester, config: config);
    final home = tester.state<HomePageState>(find.byType(HomePage));
    final editorId = home.openView('editor', instanceId: 'one', parameters: {'document': 'alpha'});
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open view: Help'));
    await tester.pumpAndSettle();
    expect(find.text('Help view'), findsOneWidget);
    expect(ic.sl<SettingsController>().settings.selectedShellTabId, 'help-1');

    await tester.tap(find.byTooltip('Editor one'));
    await tester.pumpAndSettle();
    expect(ic.sl<SettingsController>().settings.selectedShellTabId, editorId);
    expect(find.text('Status one'), findsOneWidget);
    await tester.tap(find.byTooltip('Pin editor one'));
    expect(actions, ['one']);
    await tester.tap(find.byTooltip('Open inspector'));
    await tester.pumpAndSettle();
    expect(find.text('Inspector one'), findsOneWidget);

    await tester.tap(find.text('Open help from editor'));
    await tester.pumpAndSettle();
    expect(ic.sl<SettingsController>().settings.selectedShellTabId, 'help-1');
    expect(find.text('Status one'), findsNothing);
    expect(find.text('Inspector one'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('mobile switches tabs from the header while keeping activity navigation usable', (tester) async {
    await _pumpShell(tester, size: const Size(390, 844));
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
    expect(ic.sl<SettingsController>().settings.selectedShellTabId, 'editor-1');
    expect(find.text('Document alpha'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}

ShellConfig _config({void Function(String instanceId)? onAction, Map<String, _WorkspaceStatusProvider>? providers}) =>
    ShellConfig(
      title: (_) => 'Workspace test',
      destinations: const [
        ShellDestination(id: 'activity-a', title: _activityTitleA, icon: Icons.home),
        ShellDestination(id: 'activity-b', title: _activityTitleB, icon: Icons.folder),
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
          reusePolicy: ShellViewReusePolicy.byRegistration,
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
