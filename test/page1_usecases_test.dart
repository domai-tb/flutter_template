import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app_skeleton/pages/page1/page1_datasource.dart';
import 'package:mobile_app_skeleton/pages/page1/page1_repository.dart';
import 'package:mobile_app_skeleton/pages/page1/page1_usecases.dart';

void main() {
  test('Page1Usecases returns placeholder items', () async {
    final usecases = Page1Usecases(
      repository: Page1Repository(dataSource: Page1DataSource()),
    );

    final items = await usecases.getItems();
    expect(items, isNotEmpty);
    expect(items.length, 20);
  });

  test('Page1Usecases supports query filtering', () async {
    final usecases = Page1Usecases(
      repository: Page1Repository(dataSource: Page1DataSource()),
    );

    final all = await usecases.getItems();
    final firstTitleWord = all.first.title.split(' ').last; // "1"
    final filtered = await usecases.getItems(query: firstTitleWord);

    expect(filtered, isNotEmpty);
    expect(filtered.length, lessThanOrEqualTo(all.length));
  });
}

