import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/core/app_scope.dart';
import 'package:flutter_template/core/app_services.dart';
import 'package:flutter_template/core/injection.dart' as ic;
import 'package:flutter_template/core/themes.dart';
import 'package:flutter_template/l10n/l10n.dart';
import 'package:flutter_template/pages/home/home_page.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';
import 'package:flutter_template/pages/settings/settings_controller.dart';
import 'package:flutter_template/pages/settings/settings_entity.dart';
import 'package:flutter_template/pages/settings/settings_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const runShellGoldens = bool.fromEnvironment('RUN_SHELL_GOLDENS');

  setUpAll(_loadGoldenFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ic.init();
  });

  tearDown(() async {
    await ic.sl.reset();
  });

  testWidgets(
    'wide shell golden',
    (tester) async {
      _setSize(tester, const Size(1440, 900));
      await tester.pumpWidget(_shellApp());
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold).first, matchesGoldenFile('goldens/shell_wide.png'));
    },
    skip: !runShellGoldens,
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'medium shell golden',
    (tester) async {
      _setSize(tester, const Size(960, 900));
      await tester.pumpWidget(_shellApp());
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold).first, matchesGoldenFile('goldens/shell_medium.png'));
    },
    skip: !runShellGoldens,
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'phone shell golden',
    (tester) async {
      _setSize(tester, const Size(390, 844));
      await tester.pumpWidget(_shellApp());
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold).first, matchesGoldenFile('goldens/shell_phone.png'));
    },
    skip: !runShellGoldens,
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'Settings ${brightness.name} golden',
      (tester) async {
        _setSize(tester, const Size(1440, 900));
        ic.sl<SettingsController>().update(
          ic.sl<SettingsController>().settings.copyWith(
            useSystemDarkmode: false,
            useDarkmode: brightness == Brightness.dark,
          ),
        );
        await tester.pumpWidget(_settingsApp());
        await tester.pumpAndSettle();
        await expectLater(find.byType(SettingsPage), matchesGoldenFile('goldens/settings_${brightness.name}.png'));
      },
      skip: !runShellGoldens,
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
    );
  }

  testWidgets(
    'tab overflow golden',
    (tester) async {
      _setSize(tester, const Size(1440, 900));
      final settings = ic.sl<SettingsController>();
      final tabs = [
        const ShellTabPreference(id: 'home', registrationId: 'home', destinationId: 'home'),
        for (var index = 1; index <= 20; index++)
          ShellTabPreference(id: 'preview-$index', registrationId: 'preview', destinationId: 'home'),
      ];
      settings.update(settings.settings.copyWith(shellTabs: tabs, selectedShellTabId: 'preview-20'));
      await tester.pumpWidget(_shellApp());
      await tester.pumpAndSettle();
      expect(find.text('Preview 20'), findsNWidgets(2));
      await expectLater(find.byType(Scaffold).first, matchesGoldenFile('goldens/tab_overflow.png'));
    },
    skip: !runShellGoldens,
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'inspector overlay golden',
    (tester) async {
      _setSize(tester, const Size(960, 900));
      await tester.pumpWidget(_shellApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('header-action-right-sidebar')));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold).first, matchesGoldenFile('goldens/inspector_overlay.png'));
    },
    skip: !runShellGoldens,
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _shellApp() => _app(HomePage(mainNavigatorKey: GlobalKey<NavigatorState>(), config: _shellConfig()));

Widget _settingsApp() => _app(const SettingsPage());

Widget _app(Widget home) {
  final settings = ic.sl<SettingsController>();
  return AppScope(
    settings: settings,
    services: ic.sl<AppServices>(),
    child: AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final value = settings.settings;
        final mode = value.useSystemDarkmode
            ? ThemeMode.system
            : value.useDarkmode
            ? ThemeMode.dark
            : ThemeMode.light;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: _goldenTheme(
            AppTheme.light(accentPreset: value.accentPreset, comfortable: value.density == 'comfortable'),
          ),
          darkTheme: _goldenTheme(
            AppTheme.dark(accentPreset: value.accentPreset, comfortable: value.density == 'comfortable'),
          ),
          themeMode: mode,
          home: home,
        );
      },
    ),
  );
}

ThemeData _goldenTheme(ThemeData theme) => theme.copyWith(
  textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
  primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Roboto'),
);

Future<void> _loadGoldenFonts() async {
  Future<ByteData> font(String name) async => ByteData.sublistView(await File('test/fonts/$name').readAsBytes());

  await (FontLoader('Roboto')
        ..addFont(font('Roboto-Regular.ttf'))
        ..addFont(font('Roboto-Medium.ttf'))
        ..addFont(font('Roboto-Bold.ttf')))
      .load();
  await (FontLoader('MaterialIcons')..addFont(font('MaterialIcons-Regular.otf'))).load();
}

ShellConfig _shellConfig() => ShellConfig(
  title: (_) => 'Shell preview',
  destinations: [
    ShellDestination(
      id: 'home',
      title: (_) => 'Home',
      icon: Icons.home_outlined,
      lockedVisible: true,
      builder: (_, _, _, _) => const Scaffold(body: Center(child: Text('Application content'))),
    ),
  ],
  views: [
    ShellViewRegistration(id: 'route', title: (_, _) => 'Home'),
    ShellViewRegistration(
      id: 'preview',
      title: (_, id) => id == 'preview' ? 'Preview view' : 'Preview ${id.split('-').last}',
      icon: Icons.article_outlined,
      builder: (_) => const Center(child: Text('Neutral content slot')),
      statusProviderFactory: _PreviewStatusProvider.new,
    ),
  ],
  inspectorBuilder: (_) => const Center(child: Text('Inspector content')),
);

class _PreviewStatusProvider extends ShellStatusProvider {
  final String instanceId;

  _PreviewStatusProvider(this.instanceId);

  @override
  List<ShellStatusItem> get items => [
    ShellStatusItem(id: instanceId, label: 'Template preview', icon: Icons.info_outline),
  ];
}
