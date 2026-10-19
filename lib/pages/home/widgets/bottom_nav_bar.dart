import 'package:flutter/material.dart';

import 'package:flutter_template/core/themes.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';

class BottomNavBar extends StatelessWidget {
  final String currentId;
  final List<ShellDestination> destinations;
  final ValueChanged<String> onSelected;

  const BottomNavBar({super.key, required this.currentId, required this.destinations, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacingScale = theme.extension<AppShellTokens>()?.spacingScale ?? 1;
    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      child: SizedBox(
        height: 64 * spacingScale,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: destinations.map((destination) {
              final selected = destination.id == currentId;
              final title = destination.title(context);
              return SizedBox(
                width: 72 * spacingScale,
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: title,
                  child: Tooltip(
                    message: title,
                    child: InkWell(
                      onTap: () => onSelected(destination.id),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selected ? destination.icon : destination.inactiveIcon ?? destination.icon,
                            color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 2),
                          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
