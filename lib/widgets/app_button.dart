import 'package:flutter/material.dart';

enum AppButtonType { normal, light }

/// Simple app-styled button used by the skeleton.
class AppButton extends StatelessWidget {
  /// The displayed text inside the button
  final String text;

  final double? width;

  final double height;

  /// The callback that should be executed when the button is tapped
  final VoidCallback onTap;

  /// Controls whether the button is rendered for a normal or light background.
  late final AppButtonType type;

  AppButton({
    super.key,
    required this.text,
    this.width = 330,
    this.height = 58,
    required this.onTap,
  }) {
    type = AppButtonType.normal;
  }

  AppButton.light({
    super.key,
    required this.text,
    this.width = 330,
    this.height = 58,
    required this.onTap,
  }) {
    type = AppButtonType.light;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Material(
        color: isLight
            ? (type == AppButtonType.normal
                ? Colors.black
                : const Color.fromRGBO(245, 246, 250, 1))
            : const Color.fromRGBO(34, 40, 54, 1),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          splashColor: isLight
              ? (type == AppButtonType.normal
                  ? const Color.fromRGBO(255, 255, 255, 0.12)
                  : const Color.fromRGBO(0, 0, 0, 0.06))
              : const Color.fromRGBO(255, 255, 255, 0.06),
          highlightColor: isLight
              ? (type == AppButtonType.normal
                  ? const Color.fromRGBO(255, 255, 255, 0.08)
                  : const Color.fromRGBO(0, 0, 0, 0.04))
              : const Color.fromRGBO(255, 255, 255, 0.04),
          borderRadius: BorderRadius.circular(15),
          child: Center(
            child: Text(
              text,
              style: isLight
                  ? (type == AppButtonType.normal
                      ? theme.textTheme.labelMedium
                          ?.copyWith(color: Colors.white)
                      : theme.textTheme.labelMedium?.copyWith(
                          color: const Color.fromARGB(255, 146, 146, 146)))
                  : theme.textTheme.labelMedium,
            ),
          ),
        ),
      ),
    );
  }
}
