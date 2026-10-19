import 'package:mobile_app_skeleton/pages/page2/page2_item_entity.dart';

class Page2DataSource {
  Future<List<Page2ItemEntity>> fetchItems() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final now = DateTime.now();
    return List<Page2ItemEntity>.generate(12, (i) {
      final index = i + 1;
      return Page2ItemEntity(
        id: 'p2_$index',
        title: 'Page 2 Item $index',
        location: 'Location $index',
        startsAt: now.add(Duration(days: index)),
      );
    });
  }
}

