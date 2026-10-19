import 'package:flutter_template/pages/page6/page6_item_entity.dart';
import 'package:flutter_template/pages/page6/page6_repository.dart';

class Page6Usecases {
  final Page6Repository repository;

  const Page6Usecases({required this.repository});

  Future<List<Page6ItemEntity>> getMenuItems() => repository.listItems();
}
