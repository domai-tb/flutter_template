import 'package:flutter/material.dart';

class AppIconButton extends StatelessWidget {
  final IconData icon;

  final VoidCallback onTap;

  final Color? backgroundColor;
  final Color? borderColor;

  final bool transparent;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.transparent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: !transparent
            ? Border.all(
                color: borderColor ??
                    (isLight
                        ? const Color.fromRGBO(245, 246, 250, 1)
                        : const Color.fromRGBO(34, 40, 54, 1)),
                width: 2,
              )
            : null,
      ),
      child: Material(
        color: backgroundColor ?? theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          splashColor: isLight
              ? const Color.fromRGBO(0, 0, 0, 0.04)
              : const Color.fromRGBO(255, 255, 255, 0.04),
          highlightColor: isLight
              ? const Color.fromRGBO(0, 0, 0, 0.02)
              : const Color.fromRGBO(255, 255, 255, 0.02),
          borderRadius: BorderRadius.circular(15),
          child: Center(
            child: Icon(
              icon,
              size: 22,
              color: isLight
                  ? Colors.black
                  : const Color.fromRGBO(184, 186, 191, 1),
            ),
          ),
        ),
      ),
    );
  }
}
