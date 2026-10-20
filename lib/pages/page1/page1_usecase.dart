import 'package:flutter_template/pages/page1/entities/item_entity.dart';
import 'package:flutter_template/pages/page1/page1_repository.dart';

class Page1UseCase {
  final Page1Repository repository;

  const Page1UseCase({required this.repository});

  Future<List<Page1ItemEntity>> getItems({String query = ''}) => repository.listItems(query: query);
}
