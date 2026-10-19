import 'package:flutter/material.dart';

import 'package:mobile_app_skeleton/core/app_scope.dart';
import 'package:mobile_app_skeleton/l10n/l10n_x.dart';
import 'package:mobile_app_skeleton/pages/home/page_navigator.dart';
import 'package:mobile_app_skeleton/pages/home/widgets/nav_bar_preferences_editor.dart';
import 'package:mobile_app_skeleton/widgets/app_segmented_triple_control.dart';

class Page6SettingsPage extends StatelessWidget {
  const Page6SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsController = AppScope.of(context).settings;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: AnimatedBuilder(
        animation: settingsController,
        builder: (context, _) {
          final settings = settingsController.settings;
          final orderedItems =
              orderedPageItemsFromSettings(settings.navBarItemOrder);
          final hiddenItems =
              hiddenPageItemsFromSettings(settings.hiddenNavBarItems);

          // 0 = system, 1 = light, 2 = dark
          final initialSelection = settings.useSystemDarkmode
              ? 0
              : settings.useDarkmode
                  ? 2
                  : 1;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                context.l10n.themeLabel,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              AppSegmentedTripleControl(
                leftTitle: 'System',
                centerTitle: 'Light',
                rightTitle: 'Dark',
                initialSelection: initialSelection,
                onChanged: (selected) {
                  final useSystemDarkmode = selected == 0;
                  final useDarkmode = selected == 2;

                  settingsController.update(
                    settings.copyWith(
                      useSystemDarkmode: useSystemDarkmode,
                      useDarkmode: useDarkmode,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.languageLabel,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: settings.localeCode ?? 'system',
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'system',
                    child: Text(context.l10n.languageSystem),
                  ),
                  DropdownMenuItem(
                    value: 'en',
                    child: Text(context.l10n.languageEnglish),
                  ),
                  DropdownMenuItem(
                    value: 'de',
                    child: Text(context.l10n.languageGerman),
                  ),
                ],
                onChanged: (val) {
                  if (val == null) return;
                  settingsController.update(
                    settings.copyWith(
                      localeCode: val == 'system' ? null : val,
                    ),
                  );
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
                value: settings.useSystemTextScaling,
                onChanged: (val) {
                  settingsController
                      .update(settings.copyWith(useSystemTextScaling: val));
                },
              ),
              const SizedBox(height: 24),
              NavBarPreferencesEditor(
                orderedItems: orderedItems,
                hiddenItems: hiddenItems,
                onOrderChanged: (items) {
                  settingsController.update(
                    settings.copyWith(navBarItemOrder: pageItemIds(items)),
                  );
                },
                onHiddenItemsChanged: (items) {
                  settingsController.update(
                    settings.copyWith(hiddenNavBarItems: pageItemIds(items)),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
