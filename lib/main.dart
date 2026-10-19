import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:flutter_template/core/app_scope.dart';
import 'package:flutter_template/core/app_services.dart';
import 'package:flutter_template/core/injection.dart' as ic;
import 'package:flutter_template/core/settings.dart';
import 'package:flutter_template/core/themes.dart';
import 'package:flutter_template/l10n/l10n.dart';
import 'package:flutter_template/l10n/l10n_x.dart';
import 'package:flutter_template/pages/home/home_page.dart';
import 'package:flutter_template/pages/home/onboarding.dart';

Future<void> main() async {
  if (kIsWeb) usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // Disable noisy logs in release.
  if (kReleaseMode) debugPrint = (String? message, {int? wrapWidth}) => '';

  await ic.init();
  final settings = ic.sl<SettingsController>();
  final services = ic.sl<AppServices>();

  runApp(AppScope(settings: settings, services: services, child: const SkeletonApp()));
}

class SkeletonApp extends StatefulWidget {
  const SkeletonApp({super.key});

  @override
  State<SkeletonApp> createState() => _SkeletonAppState();
}

class _SkeletonAppState extends State<SkeletonApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _mainNavigatorKey = GlobalKey<NavigatorState>();
  RouteInformation? _routeInformation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await SystemNavigator.selectMultiEntryHistory();
        final uri = _routeInformation?.uri;
        if (mounted && uri != null && (uri.pathSegments.isNotEmpty || uri.fragment.isNotEmpty)) {
          await SystemNavigator.routeInformationUpdated(uri: uri, replace: true);
        }
      });
    }
    if (kIsWeb) {
      final initialRoute = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
      _routeInformation = RouteInformation(uri: Uri.parse(initialRoute));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async {
    if (!kIsWeb) return false;
    setState(() => _routeInformation = routeInformation);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);

    return AnimatedBuilder(
      animation: scope.settings,
      builder: (context, _) {
        final settings = scope.settings.settings;
        final themeMode = settings.useSystemDarkmode
            ? ThemeMode.system
            : (settings.useDarkmode ? ThemeMode.dark : ThemeMode.light);
        final locale = settings.localeCode == null ? null : Locale(settings.localeCode!);
        Route<void> buildShellRoute(RouteSettings routeSettings) => MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => AnimatedBuilder(
            animation: scope.settings,
            builder: (context, _) => scope.settings.settings.didCompleteOnboarding
                ? HomePage(mainNavigatorKey: _mainNavigatorKey, routeInformation: _routeInformation)
                : OnboardingPage(mainNavigatorKey: _mainNavigatorKey),
          ),
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => context.l10n.appTitle,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(accentPreset: settings.accentPreset, comfortable: settings.density == 'comfortable'),
          darkTheme: AppTheme.dark(accentPreset: settings.accentPreset, comfortable: settings.density == 'comfortable'),
          themeMode: themeMode,
          locale: locale,
          onGenerateRoute: buildShellRoute,
          onGenerateInitialRoutes: (initialRoute) => [buildShellRoute(RouteSettings(name: initialRoute))],
        );
      },
    );
  }
}
