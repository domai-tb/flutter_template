import 'package:flutter_template/core/shell_notifications.dart';
import 'package:flutter_template/pages/page1/page1_usecase.dart';
import 'package:flutter_template/pages/page2/page2_usecase.dart';
import 'package:flutter_template/pages/page3/page3_usecase.dart';
import 'package:flutter_template/pages/page4/page4_usecase.dart';
import 'package:flutter_template/pages/page5/page5_usecase.dart';
import 'package:flutter_template/pages/page6/page6_usecase.dart';
import 'package:flutter_template/pages/profile/profile_usecase.dart';
import 'package:flutter_template/pages/settings/settings_usecase.dart';

/// Aggregates feature use-cases for convenient access via `AppScope`.
///
/// Wiring happens in `lib/core/injection.dart` (GetIt), so pages can stay free of
/// plugin imports.
class AppServices {
  final Page1UseCase page1;
  final Page2UseCase page2;
  final Page3UseCase page3;
  final Page4UseCase page4;
  final Page5UseCase page5;
  final Page6UseCase page6;
  final SettingsUseCase settings;
  final ShellNotificationService shellNotifications;
  final ProfileUseCase? profile;

  const AppServices({
    required this.page1,
    required this.page2,
    required this.page3,
    required this.page4,
    required this.page5,
    required this.page6,
    required this.settings,
    required this.shellNotifications,
    this.profile,
  });
}
