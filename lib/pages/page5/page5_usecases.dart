import 'package:flutter_template/pages/page5/page5_item_entity.dart';
import 'package:flutter_template/pages/page5/page5_repository.dart';

class Page5Usecases {
  final Page5Repository repository;

  const Page5Usecases({required this.repository});

  Future<List<Page5ItemEntity>> getItems() => repository.listItems();
}
