import 'package:flutter_template/pages/page6/page6_item_entity.dart';

class Page6DataSource {
  Future<List<Page6ItemEntity>> fetchItems() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return const [Page6ItemEntity(id: 'about', title: 'About', subtitle: 'About this template')];
  }
}
