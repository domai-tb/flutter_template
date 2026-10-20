import 'package:get_it/get_it.dart';

import 'package:flutter_template/core/app_services.dart';
import 'package:flutter_template/core/shell_notifications.dart';
import 'package:flutter_template/pages/page1/page1_datasource.dart';
import 'package:flutter_template/pages/page1/page1_repository.dart';
import 'package:flutter_template/pages/page1/page1_usecase.dart';
import 'package:flutter_template/pages/page2/page2_datasource.dart';
import 'package:flutter_template/pages/page2/page2_repository.dart';
import 'package:flutter_template/pages/page2/page2_usecase.dart';
import 'package:flutter_template/pages/page3/page3_datasource.dart';
import 'package:flutter_template/pages/page3/page3_repository.dart';
import 'package:flutter_template/pages/page3/page3_usecase.dart';
import 'package:flutter_template/pages/page4/page4_datasource.dart';
import 'package:flutter_template/pages/page4/page4_repository.dart';
import 'package:flutter_template/pages/page4/page4_usecase.dart';
import 'package:flutter_template/pages/page5/page5_datasource.dart';
import 'package:flutter_template/pages/page5/page5_repository.dart';
import 'package:flutter_template/pages/page5/page5_usecase.dart';
import 'package:flutter_template/pages/page6/page6_datasource.dart';
import 'package:flutter_template/pages/page6/page6_repository.dart';
import 'package:flutter_template/pages/page6/page6_usecase.dart';
import 'package:flutter_template/pages/profile/profile_datasource.dart';
import 'package:flutter_template/pages/profile/profile_repository.dart';
import 'package:flutter_template/pages/profile/profile_usecase.dart';
import 'package:flutter_template/pages/settings/settings_controller.dart';
import 'package:flutter_template/pages/settings/settings_datasource.dart';
import 'package:flutter_template/pages/settings/settings_repository.dart';
import 'package:flutter_template/pages/settings/settings_usecase.dart';

/// Global service locator (GetIt).
///
/// Keep plugin usage centralized here; UI code should access dependencies via
/// `AppScope` (or, if you prefer, via `sl<T>()` in non-UI layers).
final sl = GetIt.instance;

Future<void> init({ShellAuthProvider? authProvider}) async {
  sl.registerSingleton<SettingsDataSource>(await SharedPreferencesSettingsDataSource.create());
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepository(dataSource: sl()));
  sl.registerLazySingleton<SettingsUseCase>(() => SettingsUseCase(repository: sl()));
  sl.registerSingleton<SettingsController>(await SettingsController.load(sl()));
  sl.registerSingleton<ShellNotificationService>(ShellNotificationService());
  if (authProvider != null) {
    sl.registerSingleton<ProfileDataSource>(authProvider);
    sl.registerLazySingleton<ProfileRepository>(() => ProfileRepository(dataSource: sl()));
    sl.registerLazySingleton<ProfileUseCase>(() => ProfileUseCase(repository: sl()));
    try {
      await sl<ProfileUseCase>().restoreSession();
    } catch (_) {
      // An unavailable identity service must not prevent the app from opening in guest mode.
    }
  }

  // Page 1
  sl.registerLazySingleton<Page1DataSource>(Page1DataSource.new);
  sl.registerLazySingleton<Page1Repository>(() => Page1Repository(dataSource: sl()));
  sl.registerLazySingleton<Page1UseCase>(() => Page1UseCase(repository: sl()));

  // Page 2
  sl.registerLazySingleton<Page2DataSource>(Page2DataSource.new);
  sl.registerLazySingleton<Page2Repository>(() => Page2Repository(dataSource: sl()));
  sl.registerLazySingleton<Page2UseCase>(() => Page2UseCase(repository: sl()));

  // Page 3
  sl.registerLazySingleton<Page3DataSource>(Page3DataSource.new);
  sl.registerLazySingleton<Page3Repository>(() => Page3Repository(dataSource: sl()));
  sl.registerLazySingleton<Page3UseCase>(() => Page3UseCase(repository: sl()));

  // Page 4
  sl.registerLazySingleton<Page4DataSource>(Page4DataSource.new);
  sl.registerLazySingleton<Page4Repository>(() => Page4Repository(dataSource: sl()));
  sl.registerLazySingleton<Page4UseCase>(() => Page4UseCase(repository: sl()));

  // Page 5
  sl.registerLazySingleton<Page5DataSource>(Page5DataSource.new);
  sl.registerLazySingleton<Page5Repository>(() => Page5Repository(dataSource: sl()));
  sl.registerLazySingleton<Page5UseCase>(() => Page5UseCase(repository: sl()));

  // Page 6
  sl.registerLazySingleton<Page6DataSource>(Page6DataSource.new);
  sl.registerLazySingleton<Page6Repository>(() => Page6Repository(dataSource: sl()));
  sl.registerLazySingleton<Page6UseCase>(() => Page6UseCase(repository: sl()));

  // Aggregate wiring
  sl.registerLazySingleton<AppServices>(
    () => AppServices(
      page1: sl(),
      page2: sl(),
      page3: sl(),
      page4: sl(),
      page5: sl(),
      page6: sl(),
      settings: sl(),
      shellNotifications: sl(),
      profile: sl.isRegistered<ProfileUseCase>() ? sl<ProfileUseCase>() : null,
    ),
  );
}
