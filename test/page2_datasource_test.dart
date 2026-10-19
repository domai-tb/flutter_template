import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_template/pages/page2/page2_datasource.dart';

void main() {
  test('Page2 placeholder dates are stable across fetches', () async {
    final dataSource = Page2DataSource();

    final first = await dataSource.fetchItems();
    final second = await dataSource.fetchItems();
    expect(second.map((item) => item.startsAt).toList(), first.map((item) => item.startsAt).toList());
  });
}
