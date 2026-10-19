import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import 'package:mobile_app_skeleton/pages/home/page_navigator.dart';
import 'package:mobile_app_skeleton/pages/home/widgets/bottom_nav_bar_item.dart';

/// Creates the bottom navigation bar that lets the user switch between different pages.
class BottomNavBar extends StatefulWidget {
  /// Needs the currently active page in order to highlight it
  final PageItem currentPage;
  final List<PageItem> pages;

  /// Calls this function when an item of the navigation bar is selected.
  final Function(PageItem) onSelectedPage;

  const BottomNavBar({
    super.key,
    required this.currentPage,
    required this.pages,
    required this.onSelectedPage,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: Platform.isIOS ? 88 : 98,
      padding: Platform.isIOS
          ? const EdgeInsets.only(bottom: 20, left: 5)
          : const EdgeInsets.only(left: 7),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.pages.map((page) {
              final presentation = pageItemPresentation(context, page);

              return BottomNavBarItem(
                title: presentation.title,
                activeIcon: presentation.activeIcon,
                inactiveIcon: presentation.inactiveIcon,
                onTap: () => widget.onSelectedPage(page),
                isActive: widget.currentPage == page,
                iconPaddingLeft: presentation.iconPaddingLeft,
                iconPaddingRight: presentation.iconPaddingRight,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
