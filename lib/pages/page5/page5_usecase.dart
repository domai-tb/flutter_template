import 'package:flutter_template/pages/page5/entities/item_entity.dart';
import 'package:flutter_template/pages/page5/page5_repository.dart';

class Page5UseCase {
  final Page5Repository repository;

  const Page5UseCase({required this.repository});

  Future<List<Page5ItemEntity>> getItems() => repository.listItems();
}
