import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_template/core/settings.dart';
import 'package:flutter_template/core/themes.dart';
import 'package:flutter_template/l10n/l10n.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';
import 'package:flutter_template/pages/home/widgets/page_navigation_animation.dart';
import 'package:flutter_template/pages/home/widgets/shell_split_view.dart';

void main() {
  testWidgets('three-pane resizing preserves minimums, neighboring width, and persisted weights', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    List<double>? persistedWeights;
    final workspace =
        ShellWorkspaceController(
          initialSplitOpen: true,
          hasSplitPreference: true,
          initialWeights: const [1, 1, 1],
          onLayoutChanged: ({required isOpen, required weights, required persist}) {
            if (persist) persistedWeights = List.of(weights);
          },
        )..requestPanes([
          ShellWorkspacePane(
            id: 'left-panel',
            title: 'Left panel',
            minWidth: 300,
            builder: (_, _) => const SizedBox.expand(key: ValueKey('left-panel-content')),
          ),
          ShellWorkspacePane(
            id: 'right-panel',
            title: 'Right panel',
            minWidth: 300,
            builder: (_, _) => const SizedBox.expand(key: ValueKey('right-panel-content')),
          ),
        ]);
    addTearDown(workspace.dispose);
    final view = _viewContext(workspace);
    addTearDown(view.dispose);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: Scaffold(
          body: ListenableBuilder(
            listenable: workspace,
            builder: (context, _) => ShellSplitView(
              primary: const SizedBox.expand(key: ValueKey('primary-content')),
              view: view.context,
              workspace: workspace,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rightWidth = tester.getSize(find.byKey(const ValueKey('right-panel-content'))).width;
    await tester.drag(find.byKey(const ValueKey('shell-split-handle-0')), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byKey(const ValueKey('primary-content'))).width, greaterThanOrEqualTo(239));
    expect(tester.getSize(find.byKey(const ValueKey('left-panel-content'))).width, greaterThanOrEqualTo(299));
    expect(tester.getSize(find.byKey(const ValueKey('right-panel-content'))).width, closeTo(rightWidth, 1));
    expect(workspace.weights.reduce((left, right) => left + right), closeTo(1, 0.0001));

    Focus.of(tester.element(find.byKey(const ValueKey('shell-split-handle-0')))).requestFocus();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();

    expect(persistedWeights, workspace.weights);
    workspace.restoreLayout(isOpen: true, hasPreference: true, weights: persistedWeights!);
    expect(workspace.weights, persistedWeights);
    expect(tester.takeException(), isNull);
  });
}

class _TestViewContext {
  _TestViewContext(this._workspace);

  final ShellWorkspaceController _workspace;
  final ShellBreadcrumbController breadcrumbs = ShellBreadcrumbController();
  final ShellRightSidebarController rightSidebar = ShellRightSidebarController();
  final ShellStatusController status = ShellStatusController();
  final ShellToolbarController toolbar = ShellToolbarController();
  final ValueNotifier<ShellTabLifecycle> lifecycle = ValueNotifier(ShellTabLifecycle.activated);
  late final ShellNavigationController navigation = ShellNavigationController(
    sectionId: 'test-section',
    tabId: 'test-tab',
    openView: (_, {sectionId, instanceId, parameters = const {}, title}) async => null,
    closeTab: (_) async => true,
    activateTab: (_, _) async => true,
    selectSection: (_) async => true,
  );
  late final ShellViewContext context = ShellViewContext(
    tab: const ShellTabPreference(id: 'test-tab', registrationId: 'test-view', destinationId: 'test-section'),
    isRestored: false,
    lifecycle: lifecycle,
    mainNavigatorKey: GlobalKey<NavigatorState>(),
    entryAnimationKey: GlobalKey<AnimatedEntryState>(),
    exitAnimationKey: GlobalKey<AnimatedExitState>(),
    breadcrumbs: breadcrumbs,
    navigation: navigation,
    rightSidebar: rightSidebar,
    status: status,
    toolbar: toolbar,
    workspace: _workspace,
  );

  void dispose() {
    lifecycle.dispose();
    breadcrumbs.dispose();
    navigation.dispose();
    rightSidebar.dispose();
    status.dispose();
    toolbar.dispose();
  }
}

_TestViewContext _viewContext(ShellWorkspaceController workspace) => _TestViewContext(workspace);
