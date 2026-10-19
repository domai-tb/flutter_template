import 'package:flutter/material.dart';
import 'package:mobile_app_skeleton/l10n/l10n_x.dart';

class Page6AboutPage extends StatelessWidget {
  const Page6AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(context.l10n.aboutTitle),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          context.l10n.aboutBody,
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}
