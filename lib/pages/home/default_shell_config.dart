import 'package:flutter/material.dart';

import 'package:flutter_template/l10n/l10n_x.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';
import 'package:flutter_template/pages/page1/page1_page.dart';
import 'package:flutter_template/pages/page2/page2_page.dart';
import 'package:flutter_template/pages/page3/page3_page.dart';
import 'package:flutter_template/pages/page4/page4_page.dart';
import 'package:flutter_template/pages/page5/page5_page.dart';
import 'package:flutter_template/pages/page6/page6_page.dart';
import 'package:flutter_template/pages/settings/settings_page.dart';

Widget buildDefaultSettingsPage() => const SettingsPage();

ShellConfig defaultShellConfig() => ShellConfig(
  title: (context) => context.l10n.appTitle,
  destinations: [
    ...PageItem.values.map((item) {
      final presentation = _pageItemIcons(item);
      return ShellDestination(
        id: item.name,
        title: (context) => pageItemPresentation(context, item).title,
        icon: presentation.activeIcon,
        inactiveIcon: presentation.inactiveIcon,
        defaultViewId: item.name,
        allowedViewIds: switch (item) {
          PageItem.page1 => const {'page1', 'demo.workspace', 'demo.report'},
          PageItem.page2 => const {'page2', 'demo.session'},
          _ => {item.name},
        },
      );
    }),
    ShellDestination(
      id: 'profile',
      title: (context) => context.l10n.profile,
      icon: Icons.person_outline,
      inactiveIcon: Icons.person_outline,
      lockedVisible: true,
      isUtility: true,
      defaultViewId: 'profile',
      allowedViewIds: const {'profile'},
    ),
    ShellDestination(
      id: 'settings',
      title: (context) => context.l10n.settingsTitle,
      icon: Icons.settings_outlined,
      inactiveIcon: Icons.settings_outlined,
      lockedVisible: true,
      isUtility: true,
      defaultViewId: 'settings',
      allowedViewIds: const {'settings'},
    ),
  ],
  views: defaultShellViews(),
);

List<ShellViewRegistration> defaultShellViews() =>
    PageItem.values.map((item) {
      final presentation = _pageItemIcons(item);
      return ShellViewRegistration(
        id: item.name,
        title: (context, instanceId) {
          final title = pageItemPresentation(context, item).title;
          final instanceNumber = int.tryParse(instanceId.split('-').last);
          return instanceNumber == null || instanceNumber == 1 ? title : '$title $instanceNumber';
        },
        destinationId: item.name,
        icon: presentation.activeIcon,
        routePath: '/${item.name}',
        viewBuilder: (context, view) => _buildPageItem(context, view, item),
      );
    }).toList()..addAll([
      ShellViewRegistration(
        id: 'demo.workspace',
        title: (_, _) => 'Workspace',
        destinationId: 'page1',
        viewBuilder: (_, view) => _ShellDemoView(view: view, splitPaneCount: 1),
      ),
      ShellViewRegistration(
        id: 'demo.report',
        title: (_, _) => 'Report',
        destinationId: 'page1',
        viewBuilder: (_, view) => _ShellDemoView(view: view, splitPaneCount: 2),
      ),
      ShellViewRegistration(
        id: 'demo.session',
        title: (_, instanceId) => 'Session $instanceId',
        destinationId: 'page2',
        viewBuilder: (_, view) => _ShellDemoView(view: view),
      ),
    ]);

/// Demonstrates tab-scoped shell contributions with independent local state.
class _ShellDemoView extends StatefulWidget {
  final ShellViewContext view;
  final int splitPaneCount;

  /// Creates an example registered view for template workspaces.
  const _ShellDemoView({required this.view, this.splitPaneCount = 0});

  @override
  State<_ShellDemoView> createState() => _ShellDemoViewState();
}

class _ShellDemoViewState extends State<_ShellDemoView> {
  int _count = 0;
  String _selectedNode = 'summary';

  String get _rootId => 'demo-root:${widget.view.instanceId}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publishShellState();
    });
  }

  void _publishShellState() {
    final view = widget.view;
    final children = [
      for (final (id, label) in [('summary', 'Summary'), ('activity', 'Activity')])
        ShellNavigationNode(
          id: 'demo:$id:${view.instanceId}',
          label: label,
          parentId: _rootId,
          onActivate: () {
            setState(() => _selectedNode = id);
            _publishShellState();
          },
        ),
    ];
    view.breadcrumbs.setPath([
      ShellNavigationNode(
        id: _rootId,
        label: 'Overview',
        onActivate: () {
          setState(() => _selectedNode = 'summary');
          _publishShellState();
        },
        children: children,
      ),
      children.firstWhere((node) => node.id == 'demo:$_selectedNode:${view.instanceId}'),
    ]);
    view.status.setItem(
      ShellStatusItem(
        id: 'demo-count',
        label: 'Items: $_count',
        icon: Icons.list_alt,
        severity: ShellStatusSeverity.success,
      ),
    );
    view.rightSidebar
      ..setSelection('Item $_count')
      ..setSections([
        ShellRightSidebarSection(
          id: 'demo-details',
          title: 'Selection',
          builder: (_) => Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Tab ${view.instanceId} · $_selectedNode · $_count items'),
          ),
        ),
      ])
      ..open();
    view.toolbar.setActions([
      ShellViewAction(id: 'add-item', label: 'Add item', icon: Icons.add, onPressed: _increment),
    ]);
    if (view.tab.registrationId == 'demo.report') {
      view.workspace.requestPanes([
        for (var index = 0; index < widget.splitPaneCount; index++)
          ShellWorkspacePane(
            id: 'demo-pane-$index',
            title: 'Panel ${index + 1}',
            builder: (_, _) => Center(child: Text('Panel ${index + 1} · ${view.instanceId}')),
          ),
      ]);
    }
  }

  void _increment() {
    setState(() => _count++);
    _publishShellState();
  }

  Future<void> _openAnother() async {
    final registrationId = widget.view.tab.registrationId == 'demo.session' ? 'demo.session' : 'demo.report';
    await widget.view.navigation.openView(registrationId);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.view.tab.registrationId, style: Theme.of(context).textTheme.titleLarge),
        Text('Instance: ${widget.view.instanceId}'),
        Text('Selected: $_selectedNode · Local count: $_count'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            FilledButton(onPressed: _increment, child: const Text('Add item')),
            OutlinedButton(onPressed: _openAnother, child: const Text('Open another view')),
            OutlinedButton(onPressed: widget.view.rightSidebar.open, child: Text(context.l10n.openRightSidebar)),
          ],
        ),
      ],
    ),
  );
}

Widget _buildPageItem(BuildContext context, ShellViewContext view, PageItem item) {
  return switch (item) {
    PageItem.page1 => Page1Page(
      mainNavigatorKey: view.mainNavigatorKey,
      pageEntryAnimationKey: view.entryAnimationKey,
      pageExitAnimationKey: view.exitAnimationKey,
      view: view,
    ),
    PageItem.page2 => Page2Page(
      mainNavigatorKey: view.mainNavigatorKey,
      pageEntryAnimationKey: view.entryAnimationKey,
      pageExitAnimationKey: view.exitAnimationKey,
    ),
    PageItem.page3 => Page3Page(
      pageEntryAnimationKey: view.entryAnimationKey,
      pageExitAnimationKey: view.exitAnimationKey,
    ),
    PageItem.page4 => Page4Page(
      mainNavigatorKey: view.mainNavigatorKey,
      pageEntryAnimationKey: view.entryAnimationKey,
      pageExitAnimationKey: view.exitAnimationKey,
    ),
    PageItem.page5 => Page5Page(
      pageEntryAnimationKey: view.entryAnimationKey,
      pageExitAnimationKey: view.exitAnimationKey,
    ),
    PageItem.page6 => Page6Page(
      mainNavigatorKey: view.mainNavigatorKey,
      pageEntryAnimationKey: view.entryAnimationKey,
      pageExitAnimationKey: view.exitAnimationKey,
    ),
  };
}

PageItemPresentation _pageItemIcons(PageItem item) {
  switch (item) {
    case PageItem.page1:
      return const PageItemPresentation(title: '', activeIcon: Icons.home, inactiveIcon: Icons.home_outlined);
    case PageItem.page2:
      return const PageItemPresentation(
        title: '',
        activeIcon: Icons.calendar_month,
        inactiveIcon: Icons.calendar_month_outlined,
      );
    case PageItem.page3:
      return const PageItemPresentation(title: '', activeIcon: Icons.map, inactiveIcon: Icons.map_outlined);
    case PageItem.page4:
      return const PageItemPresentation(
        title: '',
        activeIcon: Icons.restaurant,
        inactiveIcon: Icons.restaurant_outlined,
      );
    case PageItem.page5:
      return const PageItemPresentation(
        title: '',
        activeIcon: Icons.account_balance_wallet,
        inactiveIcon: Icons.account_balance_wallet_outlined,
      );
    case PageItem.page6:
      return const PageItemPresentation(title: '', activeIcon: Icons.more_horiz, inactiveIcon: Icons.more_horiz);
  }
}
