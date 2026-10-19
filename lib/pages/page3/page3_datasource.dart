import 'package:mobile_app_skeleton/pages/page3/page3_item_entity.dart';

class Page3DataSource {
  Future<List<Page3ItemEntity>> fetchItems() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    return const [
      Page3ItemEntity(id: 'p3_1', label: 'Placeholder A', description: 'Replace with your navigation/map feature.'),
      Page3ItemEntity(id: 'p3_2', label: 'Placeholder B', description: 'This tab is intentionally generic.'),
      Page3ItemEntity(id: 'p3_3', label: 'Placeholder C', description: 'Keep the architecture; swap the details.'),
    ];
  }
}

