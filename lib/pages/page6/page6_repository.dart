import 'package:flutter_template/pages/page6/page6_datasource.dart';
import 'package:flutter_template/pages/page6/entities/item_entity.dart';

class Page6Repository {
  final Page6DataSource dataSource;

  const Page6Repository({required this.dataSource});

  Future<List<Page6ItemEntity>> listItems() => dataSource.fetchItems();
}
