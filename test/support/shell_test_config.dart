import 'package:flutter/material.dart';

import 'package:flutter_template/pages/home/page_navigator.dart';

/// A small shell fixture that does not depend on the template's example pages.
ShellConfig shellTestConfig() => ShellConfig(
  title: (_) => 'Shell test',
  destinations: const [
    ShellDestination(
      id: 'feature-a',
      title: _featureATitle,
      icon: Icons.dashboard_outlined,
      defaultViewId: 'feature-a-view',
      allowedViewIds: {'feature-a-view'},
    ),
    ShellDestination(
      id: 'feature-b',
      title: _featureBTitle,
      icon: Icons.folder_outlined,
      defaultViewId: 'feature-b-view',
      allowedViewIds: {'feature-b-view'},
    ),
  ],
  views: const [
    ShellViewRegistration(
      id: 'feature-a-view',
      title: _featureAViewTitle,
      destinationId: 'feature-a',
      viewBuilder: _featureAView,
    ),
    ShellViewRegistration(
      id: 'feature-b-view',
      title: _featureBViewTitle,
      destinationId: 'feature-b',
      routePath: '/feature-b',
      viewBuilder: _featureBView,
    ),
  ],
);

String _featureATitle(BuildContext _) => 'Feature A';
String _featureBTitle(BuildContext _) => 'Feature B';
String _featureAViewTitle(BuildContext _, String _) => 'Feature A view';
String _featureBViewTitle(BuildContext _, String _) => 'Feature B view';
Widget _featureAView(BuildContext _, ShellViewContext _) => const Center(child: Text('Feature A content'));
Widget _featureBView(BuildContext _, ShellViewContext _) => const Center(child: Text('Feature B content'));
