import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';

/// Adds a reusable sample feature using only the shell's public registration contract.
class PublicShellFeature {
  static ShellConfig registerWith(ShellConfig config) => config.copyWith(
    destinations: [
      ...config.destinations,
      ShellDestination(
        id: 'sample-feature',
        title: (_) => 'Sample feature',
        icon: Icons.extension_outlined,
        defaultViewId: 'sample-dashboard',
        allowedViewIds: const {'sample-dashboard', 'sample-document'},
      ),
      ShellDestination(
        id: 'sample-related',
        title: (_) => 'Related',
        icon: Icons.link_outlined,
        defaultViewId: 'sample-related-view',
        allowedViewIds: const {'sample-related-view'},
      ),
    ],
    views: [
      ...config.views,
      ShellViewRegistration(
        id: 'sample-dashboard',
        title: (_, _) => 'Sample dashboard',
        destinationId: 'sample-feature',
        reusePolicy: ShellViewReusePolicy.byRegistration,
        viewBuilder: (_, view) => _SampleDashboard(view: view),
      ),
      ShellViewRegistration(
        id: 'sample-document',
        title: (_, instanceId) => 'Sample $instanceId',
        destinationId: 'sample-feature',
        reusePolicy: ShellViewReusePolicy.byInstance,
        viewBuilder: (_, view) => _SampleDocument(view: view),
      ),
      ShellViewRegistration(
        id: 'sample-related-view',
        title: (_, _) => 'Related view',
        destinationId: 'sample-related',
        viewBuilder: (_, _) => const Center(child: Text('Related feature content')),
      ),
    ],
  );
}

class _SampleDashboard extends StatefulWidget {
  final ShellViewContext view;

  const _SampleDashboard({required this.view});

  @override
  State<_SampleDashboard> createState() => _SampleDashboardState();
}

class _SampleDashboardState extends State<_SampleDashboard> {
  int _count = 0;
  String _page = 'summary';

  String get _rootId => 'sample-feature-root:${widget.view.instanceId}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publish();
    });
  }

  void _publish() {
    final view = widget.view;
    final pages = [
      for (final (id, title) in [('summary', 'Summary'), ('activity', 'Activity')])
        ShellNavigationNode(
          id: 'sample-feature-$id:${view.instanceId}',
          label: title,
          parentId: _rootId,
          onActivate: () {
            setState(() => _page = id);
            _publish();
          },
        ),
    ];
    view.breadcrumbs.setPath([
      ShellNavigationNode(id: _rootId, label: 'Sample workspace', children: pages),
      pages.firstWhere((node) => node.id == 'sample-feature-$_page:${view.instanceId}'),
    ]);
    view.status.setItem(ShellStatusItem(id: 'sample-items', label: 'Sample items: $_count'));
    view.inspector
      ..setSelection('Sample item $_count')
      ..setSections([
        ShellInspectorSection(
          id: 'sample-context',
          title: 'Sample context',
          builder: (_) => Text('Inspector for ${view.instanceId}'),
        ),
      ])
      ..open();
    view.toolbar.setActions([
      ShellViewAction(id: 'sample-add', label: 'Add sample item', icon: Icons.add, onPressed: _increment),
    ]);
    view.workspace.requestPanes([
      ShellWorkspacePane(
        id: 'sample-secondary',
        title: 'Sample pane',
        builder: (_, _) => const Center(child: Text('Sample secondary pane')),
      ),
    ]);
  }

  void _increment() {
    setState(() => _count++);
    _publish();
  }

  void _openDocument(String id) => unawaited(widget.view.navigation.openView('sample-document', instanceId: id));

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sample dashboard'),
        Text('Dashboard count: $_count · Page: $_page'),
        Wrap(
          spacing: 8,
          children: [
            TextButton(key: const ValueKey('sample-increment'), onPressed: _increment, child: const Text('Increment')),
            TextButton(
              key: const ValueKey('sample-note-a'),
              onPressed: () => _openDocument('note-a'),
              child: const Text('Open note A'),
            ),
            TextButton(
              key: const ValueKey('sample-note-b'),
              onPressed: () => _openDocument('note-b'),
              child: const Text('Open note B'),
            ),
            TextButton(
              key: const ValueKey('sample-cross-section'),
              onPressed: () =>
                  unawaited(widget.view.navigation.openView('sample-related-view', sectionId: 'sample-related')),
              child: const Text('Open another section'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SampleDocument extends StatefulWidget {
  final ShellViewContext view;

  const _SampleDocument({required this.view});

  @override
  State<_SampleDocument> createState() => _SampleDocumentState();
}

class _SampleDocumentState extends State<_SampleDocument> {
  int _count = 0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Document ${widget.view.instanceId}'),
      Text('Document count: $_count', key: ValueKey('sample-document-count-${widget.view.instanceId}')),
      TextButton(onPressed: () => setState(() => _count++), child: const Text('Increment document')),
    ],
  );
}
