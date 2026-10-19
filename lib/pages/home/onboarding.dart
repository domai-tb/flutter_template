import 'package:flutter/material.dart';

import 'package:mobile_app_skeleton/core/app_scope.dart';
import 'package:mobile_app_skeleton/l10n/l10n_x.dart';
import 'package:mobile_app_skeleton/pages/home/page_navigator.dart';
import 'package:mobile_app_skeleton/pages/home/widgets/nav_bar_preferences_editor.dart';
import 'package:mobile_app_skeleton/widgets/app_segmented_triple_control.dart';

class OnboardingPage extends StatefulWidget {
  final GlobalKey<NavigatorState> mainNavigatorKey;

  const OnboardingPage({super.key, required this.mainNavigatorKey});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;
  bool _hydrated = false;

  // 0 = system, 1 = light, 2 = dark
  int _selectedTheme = 0;
  bool _useSystemTextScaling = false;
  List<PageItem> _navBarOrder = PageItem.values.toList();
  Set<PageItem> _hiddenNavBarItems = <PageItem>{};

  void _applySettings() {
    final settingsController = AppScope.of(context).settings;
    final settings = settingsController.settings;

    final useSystemDarkmode = _selectedTheme == 0;
    final useDarkmode = _selectedTheme == 2;

    settingsController.update(
      settings.copyWith(
        useSystemDarkmode: useSystemDarkmode,
        useDarkmode: useDarkmode,
        useSystemTextScaling: _useSystemTextScaling,
        navBarItemOrder: pageItemIds(_navBarOrder),
        hiddenNavBarItems: pageItemIds(_hiddenNavBarItems),
        didCompleteOnboarding: true,
      ),
    );
  }

  void _applyPreviewSettings() {
    final settingsController = AppScope.of(context).settings;
    final settings = settingsController.settings;

    final useSystemDarkmode = _selectedTheme == 0;
    final useDarkmode = _selectedTheme == 2;

    settingsController.update(
      settings.copyWith(
        useSystemDarkmode: useSystemDarkmode,
        useDarkmode: useDarkmode,
        useSystemTextScaling: _useSystemTextScaling,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = AppScope.of(context).settings.settings;

    if (!_hydrated) {
      _selectedTheme = settings.useSystemDarkmode
          ? 0
          : settings.useDarkmode
              ? 2
              : 1;
      _useSystemTextScaling = settings.useSystemTextScaling;
      _navBarOrder = orderedPageItemsFromSettings(settings.navBarItemOrder);
      _hiddenNavBarItems =
          hiddenPageItemsFromSettings(settings.hiddenNavBarItems);
      _hydrated = true;
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.shortestSide >= 600 ? 550 : null,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (idx) => setState(() => _pageIndex = idx),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(30, 60, 30, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.appTitle,
                              style: theme.textTheme.displayMedium,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              context.l10n.onboardingIntroBody,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 30),
                            Text(
                              context.l10n.onboardingIntroHint,
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(30, 60, 30, 30),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.onboardingPreferencesTitle,
                                style: theme.textTheme.displayMedium,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                context.l10n.themeLabel,
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 10),
                              AppSegmentedTripleControl(
                                leftTitle: 'System',
                                centerTitle: 'Light',
                                rightTitle: 'Dark',
                                initialSelection: _selectedTheme,
                                onChanged: (selected) {
                                  setState(() => _selectedTheme = selected);
                                  _applyPreviewSettings();
                                },
                              ),
                              const SizedBox(height: 24),
                              Text(
                                context.l10n.accessibilityLabel,
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 10),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: Text(context.l10n.useSystemTextScaling),
                                value: _useSystemTextScaling,
                                onChanged: (val) {
                                  setState(() => _useSystemTextScaling = val);
                                  _applyPreviewSettings();
                                },
                              ),
                              const SizedBox(height: 24),
                              NavBarPreferencesEditor(
                                orderedItems: _navBarOrder,
                                hiddenItems: _hiddenNavBarItems,
                                onOrderChanged: (items) {
                                  setState(() => _navBarOrder = items);
                                },
                                onHiddenItemsChanged: (items) {
                                  setState(() => _hiddenNavBarItems = items);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: _pageIndex == 0
                            ? null
                            : () => _pageController.previousPage(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                ),
                        child: Text(context.l10n.back),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          if (_pageIndex == 0) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                            );
                            return;
                          }
                          _applySettings();
                        },
                        child: Text(
                          _pageIndex == 0
                              ? context.l10n.next
                              : context.l10n.finish,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
