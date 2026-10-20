import 'package:flutter_template/pages/page3/entities/item_entity.dart';
import 'package:flutter_template/pages/page3/page3_repository.dart';

class Page3UseCase {
  final Page3Repository repository;

  const Page3UseCase({required this.repository});

  Future<List<Page3ItemEntity>> getItems() => repository.listItems();
}
