import 'package:mobile_app_skeleton/pages/page1/page1_datasource.dart';
import 'package:mobile_app_skeleton/pages/page1/page1_item_entity.dart';

class Page1Repository {
  final Page1DataSource dataSource;

  const Page1Repository({required this.dataSource});

  Future<List<Page1ItemEntity>> listItems({String query = ''}) => dataSource.fetchItems(query: query);
}

