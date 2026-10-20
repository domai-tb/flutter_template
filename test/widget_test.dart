import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/core/app_scope.dart';
import 'package:flutter_template/core/app_services.dart';
import 'package:flutter_template/core/injection.dart' as ic;
import 'package:flutter_template/pages/settings/settings_controller.dart';
import 'package:flutter_template/main.dart';
import 'package:flutter_template/pages/home/onboarding.dart';

void main() {
  testWidgets('first launch shows onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await ic.init();

    await tester.pumpWidget(
      AppScope(settings: ic.sl<SettingsController>(), services: ic.sl<AppServices>(), child: const SkeletonApp()),
    );

    expect(find.byType(OnboardingPage), findsOneWidget);
  });
}
