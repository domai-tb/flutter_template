import 'package:mobile_app_skeleton/pages/page4/page4_datasource.dart';
import 'package:mobile_app_skeleton/pages/page4/page4_item_entity.dart';

class Page4Repository {
  final Page4DataSource dataSource;

  const Page4Repository({required this.dataSource});

  Future<List<Page4ItemEntity>> listItems() => dataSource.fetchItems();
}

