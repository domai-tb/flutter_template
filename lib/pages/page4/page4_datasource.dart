import 'package:mobile_app_skeleton/pages/page4/page4_item_entity.dart';

class Page4DataSource {
  Future<List<Page4ItemEntity>> fetchItems() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return const [
      Page4ItemEntity(id: 'p4_1', title: 'Item 1', description: 'Placeholder description', price: 3.50),
      Page4ItemEntity(id: 'p4_2', title: 'Item 2', description: 'Placeholder description', price: 5.25),
      Page4ItemEntity(id: 'p4_3', title: 'Item 3', description: 'Placeholder description', price: 2.10),
      Page4ItemEntity(id: 'p4_4', title: 'Item 4', description: 'Placeholder description', price: 7.99),
    ];
  }
}

