import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/core/app_scope.dart';
import 'package:flutter_template/core/app_services.dart';
import 'package:flutter_template/core/injection.dart' as ic;
import 'package:flutter_template/core/settings.dart';
import 'package:flutter_template/core/themes.dart';
import 'package:flutter_template/l10n/l10n.dart';
import 'package:flutter_template/pages/home/home_page.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';
import 'package:flutter_template/pages/page6/page6_settings_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadGoldenFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ic.init();
  });

  tearDown(() async {
    await ic.sl.reset();
  });

  testWidgets('wide shell golden', (tester) async {
    _setSize(tester, const Size(1440, 900));
    await tester.pumpWidget(_shellApp());
    await tester.pumpAndSettle();
    await expectLater(find.byType(Scaffold).first, matchesGoldenFile('goldens/shell_wide.png'));
  });

  testWidgets('medium shell golden', (tester) async {
    _setSize(tester, const Size(960, 900));
    await tester.pumpWidget(_shellApp());
    await tester.pumpAndSettle();
    await expectLater(find.byType(Scaffold).first, matchesGoldenFile('goldens/shell_medium.png'));
  });

  testWidgets('phone shell golden', (tester) async {
    _setSize(tester, const Size(390, 844));
    await tester.pumpWidget(_shellApp());
    await tester.pumpAndSettle();
    await expectLater(find.byType(Scaffold).first, matchesGoldenFile('goldens/shell_phone.png'));
  });

  for (final brightness in Brightness.values) {
    testWidgets('Settings ${brightness.name} golden', (tester) async {
      _setSize(tester, const Size(1440, 900));
      ic.sl<SettingsController>().update(
        ic.sl<SettingsController>().settings.copyWith(
          useSystemDarkmode: false,
          useDarkmode: brightness == Brightness.dark,
        ),
      );
      await tester.pumpWidget(_settingsApp());
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold).first, matchesGoldenFile('goldens/settings_${brightness.name}.png'));
    });
  }

  testWidgets('tab overflow golden', (tester) async {
    _setSize(tester, const Size(1440, 900));
    final settings = ic.sl<SettingsController>();
    final tabs = [
      const ShellTabPreference(id: 'route', registrationId: 'route'),
      for (var index = 1; index <= 12; index++)
        ShellTabPreference(id: 'placeholder-$index', registrationId: 'placeholder'),
    ];
    settings.update(settings.settings.copyWith(shellTabs: tabs, selectedShellTabId: 'placeholder-12'));
    await tester.pumpWidget(_shellApp());
    await tester.pumpAndSettle();
    await expectLater(find.byType(Scaffold).first, matchesGoldenFile('goldens/tab_overflow.png'));
  });

  testWidgets('inspector overlay golden', (tester) async {
    _setSize(tester, const Size(960, 900));
    await tester.pumpWidget(_shellApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open inspector'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(Scaffold).first, matchesGoldenFile('goldens/inspector_overlay.png'));
  });
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _shellApp() => _app(HomePage(mainNavigatorKey: GlobalKey<NavigatorState>(), config: _shellConfig()));

Widget _settingsApp() => _app(const Page6SettingsPage());

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
      id: 'placeholder',
      title: (_, id) => 'Tab ${id.split('-').last}',
      builder: (_) => const Center(child: Text('Neutral content slot')),
    ),
  ],
  inspectorBuilder: (_) => const Center(child: Text('Inspector content')),
);
