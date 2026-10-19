import 'package:mobile_app_skeleton/pages/page1/page1_usecases.dart';
import 'package:mobile_app_skeleton/pages/page2/page2_usecases.dart';
import 'package:mobile_app_skeleton/pages/page3/page3_usecases.dart';
import 'package:mobile_app_skeleton/pages/page4/page4_usecases.dart';
import 'package:mobile_app_skeleton/pages/page5/page5_usecases.dart';
import 'package:mobile_app_skeleton/pages/page6/page6_usecases.dart';

/// Aggregates feature use-cases for convenient access via `AppScope`.
///
/// Wiring happens in `lib/core/injection.dart` (GetIt), so pages can stay free of
/// plugin imports.
class AppServices {
  final Page1Usecases page1;
  final Page2Usecases page2;
  final Page3Usecases page3;
  final Page4Usecases page4;
  final Page5Usecases page5;
  final Page6Usecases page6;

  const AppServices({
    required this.page1,
    required this.page2,
    required this.page3,
    required this.page4,
    required this.page5,
    required this.page6,
  });
}
