import 'package:flutter/material.dart';
import 'package:mobile_app_skeleton/pages/page1/page1_item_entity.dart';
import 'package:mobile_app_skeleton/l10n/l10n_x.dart';

class Page1DetailPage extends StatelessWidget {
  final Page1ItemEntity item;

  const Page1DetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(context.l10n.detailTitle),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Text(
              item.subtitle,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text('ID: ${item.id}'),
            Text('Created: ${item.createdAt.toIso8601String()}'),
            const SizedBox(height: 24),
            const Text('Replace this page with your real detail screen.'),
          ],
        ),
      ),
    );
  }
}
