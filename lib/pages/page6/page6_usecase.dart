import 'package:flutter_template/pages/page6/entities/item_entity.dart';
import 'package:flutter_template/pages/page6/page6_repository.dart';

class Page6UseCase {
  final Page6Repository repository;

  const Page6UseCase({required this.repository});

  Future<List<Page6ItemEntity>> getMenuItems() => repository.listItems();
}
