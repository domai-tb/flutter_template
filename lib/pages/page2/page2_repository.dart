import 'package:flutter_template/pages/page2/page2_datasource.dart';
import 'package:flutter_template/pages/page2/entities/item_entity.dart';

class Page2Repository {
  final Page2DataSource dataSource;

  const Page2Repository({required this.dataSource});

  Future<List<Page2ItemEntity>> listItems() => dataSource.fetchItems();
}
