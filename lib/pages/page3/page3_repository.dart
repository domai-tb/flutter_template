import 'package:mobile_app_skeleton/pages/page3/page3_datasource.dart';
import 'package:mobile_app_skeleton/pages/page3/page3_item_entity.dart';

class Page3Repository {
  final Page3DataSource dataSource;

  const Page3Repository({required this.dataSource});

  Future<List<Page3ItemEntity>> listItems() => dataSource.fetchItems();
}

