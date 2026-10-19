import 'package:flutter_template/pages/page3/page3_item_entity.dart';
import 'package:flutter_template/pages/page3/page3_repository.dart';

class Page3Usecases {
  final Page3Repository repository;

  const Page3Usecases({required this.repository});

  Future<List<Page3ItemEntity>> getItems() => repository.listItems();
}
