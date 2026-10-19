import 'package:flutter/material.dart';

import 'package:flutter_template/core/themes.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';

class BottomNavBar extends StatefulWidget {
  final String currentId;
  final List<ShellDestination> destinations;
  final ValueChanged<String> onSelected;

  const BottomNavBar({super.key, required this.currentId, required this.destinations, required this.onSelected});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _revealSelected();
  }

  @override
  void didUpdateWidget(covariant BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentId != widget.currentId) _revealSelected();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _revealSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final itemContext = _itemKeys[widget.currentId]?.currentContext;
      if (itemContext != null) {
        Scrollable.ensureVisible(
          itemContext,
          alignment: 0.5,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacingScale = theme.extension<AppShellTokens>()?.spacingScale ?? 1;
    final destinations = [
      ...widget.destinations.where((destination) => destination.showOnMobile && !destination.isUtility),
      ...widget.destinations.where((destination) => destination.showOnMobile && destination.isUtility),
    ];
    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: 64 * spacingScale,
          child: SingleChildScrollView(
            key: const ValueKey('mobile-bottom-navigation-scroll'),
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final destination in destinations)
                    SizedBox(
                      key: _itemKeys.putIfAbsent(destination.id, GlobalKey.new),
                      width: 76 * spacingScale,
                      child: Semantics(
                        key: ValueKey('bottom-navigation-item-${destination.id}'),
                        button: true,
                        selected: destination.id == widget.currentId,
                        label: destination.title(context),
                        child: Tooltip(
                          message: destination.title(context),
                          child: InkWell(
                            onTap: () => widget.onSelected(destination.id),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  destination.id == widget.currentId
                                      ? destination.icon
                                      : destination.inactiveIcon ?? destination.icon,
                                  color: destination.id == widget.currentId
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  destination.title(context),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
