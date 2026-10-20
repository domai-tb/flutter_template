import 'package:flutter_template/pages/page4/entities/item_entity.dart';
import 'package:flutter_template/pages/page4/page4_repository.dart';

class Page4UseCase {
  final Page4Repository repository;

  const Page4UseCase({required this.repository});

  Future<List<Page4ItemEntity>> getItems() => repository.listItems();
}
