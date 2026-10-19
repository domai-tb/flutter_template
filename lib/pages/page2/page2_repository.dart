import 'package:mobile_app_skeleton/pages/page2/page2_datasource.dart';
import 'package:mobile_app_skeleton/pages/page2/page2_item_entity.dart';

class Page2Repository {
  final Page2DataSource dataSource;

  const Page2Repository({required this.dataSource});

  Future<List<Page2ItemEntity>> listItems() => dataSource.fetchItems();
}

