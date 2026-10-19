import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';

import 'package:flutter_template/core/app_scope.dart';
import 'package:flutter_template/core/settings.dart';
import 'package:flutter_template/core/themes.dart';
import 'package:flutter_template/l10n/l10n_x.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';
import 'package:flutter_template/pages/home/widgets/nav_bar_preferences_editor.dart';
import 'package:flutter_template/widgets/app_segmented_triple_control.dart';

class Page6SettingsPage extends StatelessWidget {
  const Page6SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.of(context).settings;
    final paletteShortcut = defaultTargetPlatform == TargetPlatform.macOS
        ? '⌘K'
        : kIsWeb
        ? 'Ctrl+Shift+K'
        : 'Ctrl+K';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final settings = controller.settings;
          final orderedItems = orderedPageItemsFromSettings(settings.navBarItemOrder);
          final hiddenItems = hiddenPageItemsFromSettings(settings.hiddenNavBarItems);
          final themeChoice = settings.useSystemDarkmode
              ? 0
              : settings.useDarkmode
              ? 2
              : 1;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _section(context, context.l10n.themeLabel),
              AppSegmentedTripleControl(
                leftTitle: context.l10n.themeSystem,
                centerTitle: context.l10n.themeLight,
                rightTitle: context.l10n.themeDark,
                initialSelection: themeChoice,
                onChanged: (selected) {
                  controller.update(settings.copyWith(useSystemDarkmode: selected == 0, useDarkmode: selected == 2));
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: settings.accentPreset,
                decoration: InputDecoration(labelText: context.l10n.accentLabel, border: const OutlineInputBorder()),
                items: AppTheme.accents.keys
                    .map((preset) => DropdownMenuItem(value: preset, child: Text(preset)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) controller.update(settings.copyWith(accentPreset: value));
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: settings.density,
                decoration: InputDecoration(labelText: context.l10n.densityLabel, border: const OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: 'compact', child: Text(context.l10n.compactDensity)),
                  DropdownMenuItem(value: 'comfortable', child: Text(context.l10n.comfortableDensity)),
                ],
                onChanged: (value) {
                  if (value != null) controller.update(settings.copyWith(density: value));
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => controller.update(
                    settings.copyWith(
                      useSystemDarkmode: false,
                      useDarkmode: true,
                      accentPreset: 'steel',
                      density: 'compact',
                    ),
                  ),
                  icon: const Icon(Icons.restore),
                  label: Text(context.l10n.resetAppearance),
                ),
              ),
              _themePreview(context),
              const SizedBox(height: 24),
              _section(context, context.l10n.resetLayout),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restore),
                title: Text(context.l10n.restoreLayout),
                onTap: () => controller.update(
                  settings.copyWith(
                    inspectorOpen: false,
                    inspectorWidth: 320,
                    splitOpen: false,
                    splitRatio: 0.5,
                    shellTabs: const [ShellTabPreference(id: 'route', registrationId: 'route')],
                    selectedShellTabId: 'route',
                    selectedModuleId: null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              NavBarPreferencesEditor(
                orderedItems: orderedItems,
                hiddenItems: hiddenItems,
                onOrderChanged: (items) => controller.update(settings.copyWith(navBarItemOrder: pageItemIds(items))),
                onHiddenItemsChanged: (items) =>
                    controller.update(settings.copyWith(hiddenNavBarItems: pageItemIds(items))),
              ),
              const SizedBox(height: 24),
              _section(context, context.l10n.keyboardLabel),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.keyboard),
                title: Text(context.l10n.commandPalette),
                subtitle: Text(paletteShortcut),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.swap_horiz),
                title: Text(context.l10n.switchView),
                subtitle: const Text('Alt+Shift+← / Alt+Shift+→ · close: Alt+Shift+W'),
              ),
              const SizedBox(height: 24),
              _section(context, context.l10n.languageLabel),
              DropdownButtonFormField<String>(
                initialValue: settings.localeCode ?? 'system',
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: 'system', child: Text(context.l10n.languageSystem)),
                  DropdownMenuItem(value: 'en', child: Text(context.l10n.languageEnglish)),
                  DropdownMenuItem(value: 'de', child: Text(context.l10n.languageGerman)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.update(settings.copyWith(localeCode: value == 'system' ? null : value));
                  }
                },
              ),
              const SizedBox(height: 12),
              Text(context.l10n.textScalingHint, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 24),
              _section(context, context.l10n.aboutShell),
              Text(context.l10n.localStorageNote, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _confirmReset(context, controller),
                icon: const Icon(Icons.delete_outline),
                label: Text(context.l10n.resetAllPreferences),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _section(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
  );

  static Widget _themePreview(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.radio_button_checked, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(context.l10n.settingsTitle),
            const Spacer(),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(context.l10n.themeLight, style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _confirmReset(BuildContext context, SettingsController controller) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.resetAllPreferences),
        content: Text(context.l10n.resetAllConfirmation),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.confirmReset)),
        ],
      ),
    );
    if (confirm == true) controller.update(const Settings());
  }
}
