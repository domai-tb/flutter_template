import 'package:mobile_app_skeleton/pages/page5/page5_item_entity.dart';

class Page5DataSource {
  Future<List<Page5ItemEntity>> fetchItems() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const [
      Page5ItemEntity(id: 'p5_1', title: 'Card A', value: '**** 1234'),
      Page5ItemEntity(id: 'p5_2', title: 'Card B', value: '**** 5678'),
    ];
  }
}

