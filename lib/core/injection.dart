import 'package:get_it/get_it.dart';

import 'package:mobile_app_skeleton/core/app_services.dart';
import 'package:mobile_app_skeleton/core/settings.dart';
import 'package:mobile_app_skeleton/pages/page1/page1_datasource.dart';
import 'package:mobile_app_skeleton/pages/page1/page1_repository.dart';
import 'package:mobile_app_skeleton/pages/page1/page1_usecases.dart';
import 'package:mobile_app_skeleton/pages/page2/page2_datasource.dart';
import 'package:mobile_app_skeleton/pages/page2/page2_repository.dart';
import 'package:mobile_app_skeleton/pages/page2/page2_usecases.dart';
import 'package:mobile_app_skeleton/pages/page3/page3_datasource.dart';
import 'package:mobile_app_skeleton/pages/page3/page3_repository.dart';
import 'package:mobile_app_skeleton/pages/page3/page3_usecases.dart';
import 'package:mobile_app_skeleton/pages/page4/page4_datasource.dart';
import 'package:mobile_app_skeleton/pages/page4/page4_repository.dart';
import 'package:mobile_app_skeleton/pages/page4/page4_usecases.dart';
import 'package:mobile_app_skeleton/pages/page5/page5_datasource.dart';
import 'package:mobile_app_skeleton/pages/page5/page5_repository.dart';
import 'package:mobile_app_skeleton/pages/page5/page5_usecases.dart';
import 'package:mobile_app_skeleton/pages/page6/page6_datasource.dart';
import 'package:mobile_app_skeleton/pages/page6/page6_repository.dart';
import 'package:mobile_app_skeleton/pages/page6/page6_usecases.dart';

/// Global service locator (GetIt).
///
/// Keep plugin usage centralized here; UI code should access dependencies via
/// `AppScope` (or, if you prefer, via `sl<T>()` in non-UI layers).
final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerSingleton<SettingsController>(await SettingsController.load());

  // Page 1
  sl.registerLazySingleton<Page1DataSource>(Page1DataSource.new);
  sl.registerLazySingleton<Page1Repository>(
    () => Page1Repository(dataSource: sl()),
  );
  sl.registerLazySingleton<Page1Usecases>(
    () => Page1Usecases(repository: sl()),
  );

  // Page 2
  sl.registerLazySingleton<Page2DataSource>(Page2DataSource.new);
  sl.registerLazySingleton<Page2Repository>(
    () => Page2Repository(dataSource: sl()),
  );
  sl.registerLazySingleton<Page2Usecases>(
    () => Page2Usecases(repository: sl()),
  );

  // Page 3
  sl.registerLazySingleton<Page3DataSource>(Page3DataSource.new);
  sl.registerLazySingleton<Page3Repository>(
    () => Page3Repository(dataSource: sl()),
  );
  sl.registerLazySingleton<Page3Usecases>(
    () => Page3Usecases(repository: sl()),
  );

  // Page 4
  sl.registerLazySingleton<Page4DataSource>(Page4DataSource.new);
  sl.registerLazySingleton<Page4Repository>(
    () => Page4Repository(dataSource: sl()),
  );
  sl.registerLazySingleton<Page4Usecases>(
    () => Page4Usecases(repository: sl()),
  );

  // Page 5
  sl.registerLazySingleton<Page5DataSource>(Page5DataSource.new);
  sl.registerLazySingleton<Page5Repository>(
    () => Page5Repository(dataSource: sl()),
  );
  sl.registerLazySingleton<Page5Usecases>(
    () => Page5Usecases(repository: sl()),
  );

  // Page 6
  sl.registerLazySingleton<Page6DataSource>(Page6DataSource.new);
  sl.registerLazySingleton<Page6Repository>(
    () => Page6Repository(dataSource: sl()),
  );
  sl.registerLazySingleton<Page6Usecases>(
    () => Page6Usecases(repository: sl()),
  );

  // Aggregate wiring
  sl.registerLazySingleton<AppServices>(
    () => AppServices(
      page1: sl(),
      page2: sl(),
      page3: sl(),
      page4: sl(),
      page5: sl(),
      page6: sl(),
    ),
  );
}
