import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_template/core/app_scope.dart';
import 'package:flutter_template/core/settings.dart';
import 'package:flutter_template/core/themes.dart';
import 'package:flutter_template/l10n/l10n_x.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';
import 'package:flutter_template/pages/home/widgets/nav_bar_preferences_editor.dart';
import 'package:flutter_template/widgets/app_segmented_triple_control.dart';

class Page6SettingsPage extends StatefulWidget {
  const Page6SettingsPage({super.key});

  @override
  State<Page6SettingsPage> createState() => _Page6SettingsPageState();
}

class _Page6SettingsPageState extends State<Page6SettingsPage> {
  int _selectedSection = 0;
  final List<FocusNode> _sectionFocusNodes = List.generate(
    6,
    (index) => FocusNode(debugLabel: 'Settings section $index'),
  );

  @override
  void dispose() {
    for (final node in _sectionFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).settings;
    final phone = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            if (phone) {
              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (var index = 0; index < 6; index++)
                    ExpansionTile(
                      key: ValueKey('settings-section-$index'),
                      initiallyExpanded: index == 0,
                      title: Text(_sectionTitle(context, index)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          child: _sectionContent(context, index, controller.settings, controller, phone: true),
                        ),
                      ],
                    ),
                ],
              );
            }
            final metrics = AppTheme.metrics(context, phone: false);
            if (constraints.maxWidth < 800) {
              final selectorHeight = (32 * MediaQuery.textScalerOf(context).scale(1)).clamp(32, 64).toDouble();
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Row(
                      children: [
                        Text(context.l10n.settingsTitle, style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: selectorHeight,
                            child: DropdownButton<int>(
                              key: const ValueKey('settings-section-selector'),
                              value: _selectedSection,
                              isExpanded: true,
                              isDense: true,
                              items: [
                                for (var index = 0; index < 6; index++)
                                  DropdownMenuItem(value: index, child: Text(_sectionTitle(context, index))),
                              ],
                              onChanged: (index) {
                                if (index != null) setState(() => _selectedSection = index);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: ConstrainedBox(
                          key: const ValueKey('settings-form'),
                          constraints: BoxConstraints(maxWidth: metrics.settingsMaxWidth),
                          child: _sectionContent(
                            context,
                            _selectedSection,
                            controller.settings,
                            controller,
                            phone: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _desktopSectionNavigation(context),
                const VerticalDivider(width: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(
                        key: const ValueKey('settings-form'),
                        constraints: BoxConstraints(maxWidth: metrics.settingsMaxWidth),
                        child: _sectionContent(
                          context,
                          _selectedSection,
                          controller.settings,
                          controller,
                          phone: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _desktopSectionNavigation(BuildContext context) {
    final theme = Theme.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final baseRowHeight = theme.extension<AppShellTokens>()?.comfortable == true ? 36 : 32;
    final rowHeight = (baseRowHeight * scale).clamp(32, 64).toDouble();
    return SizedBox(
      key: const ValueKey('settings-section-navigation'),
      width: 184,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          for (var index = 0; index < 6; index++) ...[
            if (index > 0) const SizedBox(height: 2),
            Tooltip(
              message: _sectionTitle(context, index),
              child: Focus(
                focusNode: _sectionFocusNodes[index],
                onKeyEvent: (_, event) => _handleSectionKey(index, event),
                child: Semantics(
                  button: true,
                  selected: _selectedSection == index,
                  label: _sectionTitle(context, index),
                  child: SizedBox(
                    key: ValueKey('settings-section-$index'),
                    height: rowHeight,
                    child: Material(
                      color: _selectedSection == index
                          ? theme.colorScheme.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        hoverColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                        focusColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                        onTap: () {
                          _sectionFocusNodes[index].requestFocus();
                          setState(() => _selectedSection = index);
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 2,
                              height: 18,
                              decoration: BoxDecoration(
                                color: _selectedSection == index ? theme.colorScheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _sectionIcon(index),
                              size: 16,
                              color: _selectedSection == index
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _sectionTitle(context, index),
                                maxLines: scale > 1.25 ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  KeyEventResult _handleSectionKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space) {
      setState(() => _selectedSection = index);
      return KeyEventResult.handled;
    }
    final nextIndex = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowDown => index + 1,
      LogicalKeyboardKey.arrowUp => index - 1,
      _ => index,
    };
    if (nextIndex == index) return KeyEventResult.ignored;
    final boundedIndex = nextIndex.clamp(0, _sectionFocusNodes.length - 1);
    setState(() => _selectedSection = boundedIndex);
    _sectionFocusNodes[boundedIndex].requestFocus();
    return KeyEventResult.handled;
  }

  String _sectionTitle(BuildContext context, int index) => switch (index) {
    0 => context.l10n.settingsAppearance,
    1 => context.l10n.settingsLayout,
    2 => context.l10n.settingsNavigation,
    3 => context.l10n.settingsKeyboard,
    4 => context.l10n.settingsNotifications,
    _ => context.l10n.settingsAbout,
  };

  IconData _sectionIcon(int index) => switch (index) {
    0 => Icons.palette_outlined,
    1 => Icons.view_quilt_outlined,
    2 => Icons.navigation_outlined,
    3 => Icons.keyboard_outlined,
    4 => Icons.notifications_none,
    _ => Icons.info_outline,
  };

  Widget _sectionContent(
    BuildContext context,
    int index,
    Settings settings,
    SettingsController controller, {
    required bool phone,
  }) => switch (index) {
    0 => _appearance(context, settings, controller, phone: phone),
    1 => _layout(context, settings, controller, phone: phone),
    2 => _navigation(context, settings, controller),
    3 => _keyboard(context),
    4 => _notifications(context),
    _ => _about(context, controller),
  };

  Widget _appearance(BuildContext context, Settings settings, SettingsController controller, {required bool phone}) {
    final themeChoice = settings.useSystemDarkmode
        ? 0
        : settings.useDarkmode
        ? 2
        : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(context, context.l10n.themeLabel),
        AppSegmentedTripleControl(
          leftTitle: context.l10n.themeSystem,
          centerTitle: context.l10n.themeLight,
          rightTitle: context.l10n.themeDark,
          initialSelection: themeChoice,
          onChanged: (selected) {
            controller.update(settings.copyWith(useSystemDarkmode: selected == 0, useDarkmode: selected == 2));
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: settings.accentPreset,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.l10n.accentLabel, isDense: !phone),
          items: AppTheme.accents.keys.map((preset) => DropdownMenuItem(value: preset, child: Text(preset))).toList(),
          onChanged: (value) {
            if (value != null) controller.update(settings.copyWith(accentPreset: value));
          },
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => controller.update(
              settings.copyWith(useSystemDarkmode: false, useDarkmode: true, accentPreset: 'steel'),
            ),
            icon: const Icon(Icons.restore),
            label: Text(context.l10n.resetAppearance),
          ),
        ),
      ],
    );
  }

  Widget _layout(BuildContext context, Settings settings, SettingsController controller, {required bool phone}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(context, context.l10n.densityLabel),
        DropdownButtonFormField<String>(
          initialValue: settings.density,
          isDense: !phone,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.l10n.densityLabel),
          items: [
            DropdownMenuItem(value: 'compact', child: Text(context.l10n.compactDensity)),
            DropdownMenuItem(value: 'comfortable', child: Text(context.l10n.comfortableDensity)),
          ],
          onChanged: (value) {
            if (value != null) controller.update(settings.copyWith(density: value));
          },
        ),
        const SizedBox(height: 12),
        _densityPreview(context),
        const SizedBox(height: 16),
        ListTile(
          dense: !phone,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.restore),
          title: Text(context.l10n.restoreLayout),
          onTap: () => controller.update(
            settings.copyWith(
              inspectorOpen: false,
              inspectorWidth: 320,
              splitOpen: false,
              splitRatio: 0.5,
              shellTabs: const [ShellTabPreference(id: 'page1', registrationId: 'page1', destinationId: 'page1')],
              selectedShellTabId: 'page1',
              selectedModuleId: null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _navigation(BuildContext context, Settings settings, SettingsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NavBarPreferencesEditor(
          orderedItems: orderedPageItemsFromSettings(settings.navBarItemOrder),
          hiddenItems: hiddenPageItemsFromSettings(settings.hiddenNavBarItems),
          onOrderChanged: (items) => controller.update(settings.copyWith(navBarItemOrder: pageItemIds(items))),
          onHiddenItemsChanged: (items) => controller.update(settings.copyWith(hiddenNavBarItems: pageItemIds(items))),
        ),
        const SizedBox(height: 20),
        _sectionHeading(context, context.l10n.languageLabel),
        DropdownButtonFormField<String>(
          initialValue: settings.localeCode ?? 'system',
          isExpanded: true,
          decoration: const InputDecoration(),
          items: [
            DropdownMenuItem(value: 'system', child: Text(context.l10n.languageSystem)),
            DropdownMenuItem(value: 'en', child: Text(context.l10n.languageEnglish)),
            DropdownMenuItem(value: 'de', child: Text(context.l10n.languageGerman)),
          ],
          onChanged: (value) {
            if (value != null) controller.update(settings.copyWith(localeCode: value == 'system' ? null : value));
          },
        ),
      ],
    );
  }

  Widget _keyboard(BuildContext context) {
    final paletteShortcut = defaultTargetPlatform == TargetPlatform.macOS
        ? '⌘K'
        : kIsWeb
        ? 'Ctrl+Shift+K'
        : 'Ctrl+K';
    final closeShortcut = defaultTargetPlatform == TargetPlatform.macOS
        ? '⌘W'
        : kIsWeb
        ? 'Alt+Shift+W'
        : 'Ctrl+W';
    final cycleShortcut = kIsWeb ? context.l10n.openTabOverflow : 'Ctrl+Tab / Ctrl+Shift+Tab';
    return Column(
      children: [
        _shortcutRow(context.l10n.commandPalette, paletteShortcut),
        _shortcutRow(context.l10n.closeTab, closeShortcut),
        _shortcutRow(context.l10n.switchView, cycleShortcut),
        _shortcutRow(context.l10n.openTabOverflow, 'Ctrl+1–9'),
      ],
    );
  }

  Widget _notifications(BuildContext context) =>
      Text(context.l10n.notificationPrivacyNote, style: Theme.of(context).textTheme.bodyMedium);

  Widget _about(BuildContext context, SettingsController controller) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(context.l10n.localStorageNote, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 12),
      Text(context.l10n.textScalingHint, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: () => _confirmReset(context, controller),
        icon: const Icon(Icons.delete_outline),
        label: Text(context.l10n.resetAllPreferences),
      ),
    ],
  );

  Widget _densityPreview(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = AppTheme.metrics(context, phone: false);
    final tokens = theme.extension<AppShellTokens>()!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Container(
              height: metrics.tabHeight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(bottom: BorderSide(color: theme.colorScheme.primary, width: 2)),
              ),
              child: Text(context.l10n.page1Title, style: theme.textTheme.labelSmall),
            ),
            Container(
              width: metrics.railWidth,
              height: metrics.railWidth,
              decoration: BoxDecoration(color: tokens.raised, borderRadius: BorderRadius.circular(4)),
              child: Icon(Icons.home_outlined, size: 18, color: theme.colorScheme.primary),
            ),
            Container(
              height: metrics.controlHeight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(context.l10n.searchLabel, style: theme.textTheme.labelSmall),
            ),
            Text('${metrics.tabHeight.toInt()} / ${metrics.railWidth.toInt()} / ${metrics.controlHeight.toInt()} DP'),
          ],
        ),
      ),
    );
  }

  Widget _shortcutRow(String title, String shortcut) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    trailing: Text(shortcut, style: Theme.of(context).textTheme.labelSmall),
  );

  Widget _sectionHeading(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall),
  );

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
