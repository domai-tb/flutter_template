import 'dart:math';

import 'package:mobile_app_skeleton/pages/page1/page1_item_entity.dart';

/// Placeholder data source.
///
/// Replace this with real API/storage access when turning the template into a real app.
class Page1DataSource {
  final Random _random = Random();

  Future<List<Page1ItemEntity>> fetchItems({String query = ''}) async {
    // Simulate a small delay so loading states can be tested.
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final now = DateTime.now();
    final items = List<Page1ItemEntity>.generate(20, (i) {
      final index = i + 1;
      return Page1ItemEntity(
        id: 'p1_$index',
        title: 'Page 1 Item $index',
        subtitle: 'Placeholder subtitle ${_random.nextInt(9999)}',
        createdAt: now.subtract(Duration(hours: index * 6)),
      );
    });

    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return items;

    return items
        .where((e) => e.title.toLowerCase().contains(trimmed) || e.subtitle.toLowerCase().contains(trimmed))
        .toList(growable: false);
  }
}

