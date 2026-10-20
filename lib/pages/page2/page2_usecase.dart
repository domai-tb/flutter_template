import 'package:flutter_template/pages/page2/entities/item_entity.dart';
import 'package:flutter_template/pages/page2/page2_repository.dart';

class Page2UseCase {
  final Page2Repository repository;

  const Page2UseCase({required this.repository});

  Future<List<Page2ItemEntity>> getItems() => repository.listItems();
}
