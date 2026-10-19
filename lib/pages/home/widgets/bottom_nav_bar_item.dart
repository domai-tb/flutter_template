import 'package:flutter/material.dart';
import 'package:mobile_app_skeleton/widgets/custom_button.dart';

/// A widget that displays an item in the bottom navigation menu which allows the user
/// to switch between different pages. When active, the whole item is moved up and the title
/// text fades in while also moving up. The item also changes its icon-color when it's the
/// active navigation menu item.
class BottomNavBarItem extends StatefulWidget {
  final IconData activeIcon;
  final IconData inactiveIcon;

  /// Padding above and below the icon
  final double iconVerticalPadding;
  final double iconPaddingLeft;
  final double iconPaddingRight;

  /// Title of the page that this menu item refers to
  final String title;

  /// Callback that should be called whenever the button is tapped
  final VoidCallback onTap;

  /// Wether the refered page is the currently displayed one
  final bool isActive;

  const BottomNavBarItem({
    super.key,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.title,
    this.iconVerticalPadding = 10,
    this.iconPaddingLeft = 10,
    this.iconPaddingRight = 10,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<BottomNavBarItem> createState() => _BottomNavBarItemState();
}

class _BottomNavBarItemState extends State<BottomNavBarItem> {
  // Adjust this value in order to change the icon height of each navbar-element
  static const double iconHeight = 26;
  // Adjust this value in order to change the animation curve that is used for the
  // vertical translation-animation
  static const Curve animationCurve = Curves.easeOutExpo;
  // Adjust this value in order to change the animation speed that is used for
  // all animations
  static const Duration animationDuration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Padding(
      padding: EdgeInsets.only(left: widget.iconPaddingLeft, right: widget.iconPaddingRight),
      child: AnimatedPadding(
        padding: widget.isActive ? const EdgeInsets.only(top: 2) : const EdgeInsets.only(top: 11),
        duration: animationDuration,
        curve: animationCurve,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon-button
            CustomButton(
              tapHandler: () => widget.onTap(),
              child: Padding(
                padding: EdgeInsets.only(
                  top: widget.iconVerticalPadding,
                  bottom: widget.iconVerticalPadding,
                ),
                child: Icon(
                  widget.isActive ? widget.activeIcon : widget.inactiveIcon,
                  size: iconHeight,
                  color: widget.isActive
                      ? theme.colorScheme.secondary
                      : (isLight ? Colors.black : const Color.fromRGBO(184, 186, 191, 1)),
                ),
              ),
            ),
            // Text
            AnimatedPadding(
              padding: widget.isActive ? EdgeInsets.zero : const EdgeInsets.only(top: 10),
              duration: animationDuration,
              curve: animationCurve,
              child: AnimatedOpacity(
                opacity: widget.isActive ? 1 : 0,
                duration: animationDuration,
                child: Text(
                  widget.title,
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
