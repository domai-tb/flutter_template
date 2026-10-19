import 'package:mobile_app_skeleton/pages/page5/page5_datasource.dart';
import 'package:mobile_app_skeleton/pages/page5/page5_item_entity.dart';

class Page5Repository {
  final Page5DataSource dataSource;

  const Page5Repository({required this.dataSource});

  Future<List<Page5ItemEntity>> listItems() => dataSource.fetchItems();
}

