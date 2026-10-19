import 'package:flutter/material.dart';
import 'package:mobile_app_skeleton/widgets/custom_button.dart';

class SideNavBarItem extends StatefulWidget {
  final IconData activeIcon;
  final IconData inactiveIcon;

  /// Set the icon height
  final double iconHeight;

  // Set the padding below the icon
  final double bottomIconPadding;

  // Set the padding at the top and bottom of the whole item
  final double verticalPadding;

  /// Title of the page that this menu item refers to
  final String title;

  /// Callback that should be called whenever the button is tapped
  final VoidCallback onTap;

  /// Wether the refered page is the currently displayed one
  final bool isActive;

  const SideNavBarItem({
    super.key,
    required this.activeIcon,
    required this.inactiveIcon,
    this.iconHeight = 26,
    this.bottomIconPadding = 5,
    this.verticalPadding = 10,
    required this.title,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<SideNavBarItem> createState() => _SideNavBarItemState();
}

class _SideNavBarItemState extends State<SideNavBarItem> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child:
          // Icon-button
          CustomButton(
        tapHandler: () => widget.onTap(),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: widget.verticalPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 14, right: 14, bottom: widget.bottomIconPadding),
                child: Icon(
                  widget.isActive ? widget.activeIcon : widget.inactiveIcon,
                  size: widget.iconHeight,
                  color: widget.isActive
                      ? theme.colorScheme.secondary
                      : (isLight ? Colors.black : const Color.fromRGBO(184, 186, 191, 1)),
                ),
              ),
              // Text
              Text(
                widget.title,
                style: widget.isActive
                    ? theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)
                    : theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
