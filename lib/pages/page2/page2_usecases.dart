import 'package:mobile_app_skeleton/pages/page2/page2_item_entity.dart';
import 'package:mobile_app_skeleton/pages/page2/page2_repository.dart';

class Page2Usecases {
  final Page2Repository repository;

  const Page2Usecases({required this.repository});

  Future<List<Page2ItemEntity>> getItems() => repository.listItems();
}

