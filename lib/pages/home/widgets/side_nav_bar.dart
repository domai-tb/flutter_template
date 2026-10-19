import 'package:flutter/material.dart';

import 'package:mobile_app_skeleton/pages/home/page_navigator.dart';
import 'package:mobile_app_skeleton/pages/home/widgets/side_nav_bar_item.dart';

class SideNavBar extends StatefulWidget {
  /// Needs the currently active page in order to highlight it
  final PageItem currentPage;
  final List<PageItem> pages;

  /// Calls this function when an item of the navigation bar is selected.
  final Function(PageItem) onSelectedPage;

  const SideNavBar({
    super.key,
    required this.currentPage,
    required this.pages,
    required this.onSelectedPage,
  });

  @override
  State<SideNavBar> createState() => _SideNavBarState();
}

class _SideNavBarState extends State<SideNavBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      width: 80,
      padding: const EdgeInsets.only(top: 40, bottom: 10, left: 15, right: 15),
      decoration: BoxDecoration(
        color:
            isLight ? const Color.fromRGBO(245, 246, 250, 1) : theme.cardColor,
      ),
      child: Column(
        children: widget.pages.map((page) {
          final presentation = pageItemPresentation(context, page);

          return SideNavBarItem(
            title: presentation.title,
            activeIcon: presentation.activeIcon,
            inactiveIcon: presentation.inactiveIcon,
            onTap: () => widget.onSelectedPage(page),
            isActive: widget.currentPage == page,
          );
        }).toList(),
      ),
    );
  }
}
