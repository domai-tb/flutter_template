import 'package:mobile_app_skeleton/pages/page1/page1_item_entity.dart';
import 'package:mobile_app_skeleton/pages/page1/page1_repository.dart';

class Page1Usecases {
  final Page1Repository repository;

  const Page1Usecases({required this.repository});

  Future<List<Page1ItemEntity>> getItems({String query = ''}) => repository.listItems(query: query);
}

