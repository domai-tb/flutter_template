import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_template/core/settings.dart';
import 'package:flutter_template/l10n/l10n_x.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';

class ShellPaletteCommand {
  final String id;
  final String title;
  final String shortcut;
  final FutureOr<void> Function() run;

  const ShellPaletteCommand({required this.id, required this.title, required this.shortcut, required this.run});
}

class ShellCommandPaletteDialog extends StatefulWidget {
  final List<ShellPaletteCommand> commands;

  const ShellCommandPaletteDialog({super.key, required this.commands});

  @override
  State<ShellCommandPaletteDialog> createState() => _ShellCommandPaletteDialogState();
}

class _ShellCommandPaletteDialogState extends State<ShellCommandPaletteDialog> {
  final TextEditingController _controller = TextEditingController();
  int _selectedIndex = 0;

  List<ShellPaletteCommand> get _filtered =>
      widget.commands.where((command) => command.title.toLowerCase().contains(_controller.text.toLowerCase())).toList();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSelected(int index) {
    final filtered = _filtered;
    if (index < 0 || index >= filtered.length) return;
    final command = filtered[index];
    Navigator.of(context).pop();
    unawaited(Future<void>.sync(command.run));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    _selectedIndex = filtered.isEmpty ? 0 : _selectedIndex.clamp(0, filtered.length - 1);
    final listHeight = (MediaQuery.sizeOf(context).height - 128).clamp(160.0, 400.0);

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: (MediaQuery.sizeOf(context).height - 32).clamp(240.0, 560.0),
        ),
        child: Focus(
          autofocus: true,
          onKeyEvent: (_, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            if (event.logicalKey == LogicalKeyboardKey.arrowDown && filtered.isNotEmpty) {
              setState(() => _selectedIndex = (_selectedIndex + 1) % filtered.length);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowUp && filtered.isNotEmpty) {
              setState(() => _selectedIndex = (_selectedIndex - 1 + filtered.length) % filtered.length);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.enter && filtered.isNotEmpty) {
              _runSelected(_selectedIndex);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).pop();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: context.l10n.commandPaletteHint,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() => _selectedIndex = 0),
                  onSubmitted: (_) => _runSelected(_selectedIndex),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: listHeight,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => ListTile(
                      key: ValueKey(filtered[index].id),
                      selected: _selectedIndex == index,
                      leading: const Icon(Icons.arrow_forward),
                      title: Text(filtered[index].title),
                      trailing: filtered[index].shortcut.isEmpty ? null : Text(filtered[index].shortcut),
                      onTap: () => _runSelected(index),
                    ),
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

class ShellOpenTabsSearchDialog extends StatefulWidget {
  final List<ShellTabPreference> tabs;
  final String Function(ShellTabPreference) title;
  final String Function(ShellTabPreference) sectionTitle;

  const ShellOpenTabsSearchDialog({super.key, required this.tabs, required this.title, required this.sectionTitle});

  @override
  State<ShellOpenTabsSearchDialog> createState() => _ShellOpenTabsSearchDialogState();
}

class _ShellOpenTabsSearchDialogState extends State<ShellOpenTabsSearchDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final matches = widget.tabs.where((tab) {
      final searchable =
          '${widget.title(tab)} ${widget.sectionTitle(tab)} ${tab.registrationId} ${tab.instanceId ?? ''}';
      return searchable.toLowerCase().contains(query);
    }).toList();

    return AlertDialog(
      title: Text(context.l10n.searchOpenTabs),
      content: SizedBox(
        width: 520,
        height: 420,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: context.l10n.searchOpenTabs),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: matches.isEmpty
                  ? Center(child: Text(context.l10n.noOpenTabsMatch))
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final tab = matches[index];
                        return ListTile(
                          key: ValueKey('open-tab-search-${tab.id}'),
                          leading: const Icon(Icons.tab_outlined),
                          title: Text(widget.title(tab), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(widget.sectionTitle(tab), maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => Navigator.of(context).pop(tab),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel))],
    );
  }
}

class ShellViewPickerDialog extends StatefulWidget {
  final List<ShellViewRegistration> views;
  final String Function(ShellViewRegistration) title;

  const ShellViewPickerDialog({super.key, required this.views, required this.title});

  @override
  State<ShellViewPickerDialog> createState() => _ShellViewPickerDialogState();
}

class _ShellViewPickerDialogState extends State<ShellViewPickerDialog> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.views
        .where((view) => widget.title(view).toLowerCase().contains(_search.text.toLowerCase()))
        .toList();
    return AlertDialog(
      title: Text(context.l10n.viewPickerTitle),
      content: SizedBox(
        width: 420,
        height: 360,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              controller: _search,
              decoration: InputDecoration(hintText: context.l10n.viewPickerHint, prefixIcon: const Icon(Icons.search)),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final view = results[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(view.icon ?? Icons.insert_drive_file_outlined),
                    title: Text(widget.title(view)),
                    onTap: () => Navigator.of(context).pop(view),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShellTabOverflowDialog extends StatefulWidget {
  final List<ShellTabPreference> tabs;
  final String Function(ShellTabPreference) title;

  const ShellTabOverflowDialog({super.key, required this.tabs, required this.title});

  @override
  State<ShellTabOverflowDialog> createState() => _ShellTabOverflowDialogState();
}

class _ShellTabOverflowDialogState extends State<ShellTabOverflowDialog> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.tabs
        .where((tab) => widget.title(tab).toLowerCase().contains(_search.text.toLowerCase()))
        .toList();
    return AlertDialog(
      title: Text(context.l10n.tabOverflowTitle),
      content: SizedBox(
        width: 420,
        height: 360,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              controller: _search,
              decoration: InputDecoration(hintText: context.l10n.searchLabel, prefixIcon: const Icon(Icons.search)),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) => ListTile(
                  dense: true,
                  title: Text(widget.title(results[index])),
                  onTap: () => Navigator.of(context).pop(results[index].id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
