import 'package:flutter_template/pages/page5/page5_datasource.dart';
import 'package:flutter_template/pages/page5/entities/item_entity.dart';

class Page5Repository {
  final Page5DataSource dataSource;

  const Page5Repository({required this.dataSource});

  Future<List<Page5ItemEntity>> listItems() => dataSource.fetchItems();
}
