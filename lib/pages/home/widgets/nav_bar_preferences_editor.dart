import 'package:flutter/material.dart';

import 'package:flutter_template/l10n/l10n_x.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';

class NavBarPreferencesEditor extends StatelessWidget {
  final List<PageItem> orderedItems;
  final Set<PageItem> hiddenItems;
  final ValueChanged<List<PageItem>> onOrderChanged;
  final ValueChanged<Set<PageItem>> onHiddenItemsChanged;

  const NavBarPreferencesEditor({
    super.key,
    required this.orderedItems,
    required this.hiddenItems,
    required this.onOrderChanged,
    required this.onHiddenItemsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    void move(int index, int offset) {
      final nextIndex = index + offset;
      if (nextIndex < 0 || nextIndex >= orderedItems.length) return;
      final items = List<PageItem>.from(orderedItems);
      final item = items.removeAt(index);
      items.insert(nextIndex, item);
      onOrderChanged(items);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.navigationLabel, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(context.l10n.navigationOrderHint, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text(context.l10n.navigationSettingsAlwaysVisibleHint, style: theme.textTheme.labelSmall),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          buildDefaultDragHandles: false,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orderedItems.length,
          onReorderItem: (oldIndex, newIndex) {
            final nextItems = List<PageItem>.from(orderedItems);
            final item = nextItems.removeAt(oldIndex);
            nextItems.insert(newIndex, item);
            onOrderChanged(nextItems);
          },
          itemBuilder: (context, index) {
            final item = orderedItems[index];
            final presentation = pageItemPresentation(context, item);
            final isVisible = !hiddenItems.contains(item);

            return Padding(
              key: ValueKey(item.name),
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  leading: Icon(isVisible ? presentation.activeIcon : presentation.inactiveIcon),
                  title: Text(presentation.title),
                  subtitle: Text(context.l10n.navigationVisibilityLabel),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch.adaptive(
                        value: isVisible,
                        onChanged: (value) {
                          final nextHiddenItems = Set<PageItem>.from(hiddenItems);
                          if (value) {
                            nextHiddenItems.remove(item);
                          } else {
                            nextHiddenItems.add(item);
                          }
                          onHiddenItemsChanged(nextHiddenItems);
                        },
                      ),
                      IconButton(
                        tooltip: context.l10n.moveUp,
                        onPressed: index == 0 ? null : () => move(index, -1),
                        icon: const Icon(Icons.arrow_upward),
                      ),
                      IconButton(
                        tooltip: context.l10n.moveDown,
                        onPressed: index == orderedItems.length - 1 ? null : () => move(index, 1),
                        icon: const Icon(Icons.arrow_downward),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.drag_handle)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
