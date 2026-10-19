import 'package:flutter/material.dart';
import 'package:mobile_app_skeleton/l10n/l10n_x.dart';
import 'package:mobile_app_skeleton/widgets/app_icon_button.dart';

/// This widget displays a search bar that can be hidden via a button
/// and is used to search the news feed and events.
class AppSearchBar extends StatelessWidget {
  final bool arrowHidden;
  final double horizontalPadding;
  final void Function() onBack;
  final void Function(String) onChange;

  const AppSearchBar({
    super.key,
    this.arrowHidden = false,
    this.horizontalPadding = 20,
    required this.onBack,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        height: 55,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: isLight
              ? const Color.fromRGBO(245, 246, 250, 1)
              : const Color.fromRGBO(34, 40, 54, 1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!arrowHidden) ...[
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: AppIconButton(
                  icon: Icons.arrow_back,
                  onTap: onBack,
                  transparent: true,
                  backgroundColor: isLight
                      ? const Color.fromRGBO(245, 246, 250, 1)
                      : const Color.fromRGBO(34, 40, 54, 1),
                  borderColor: isLight
                      ? const Color.fromRGBO(245, 246, 250, 1)
                      : const Color.fromRGBO(34, 40, 54, 1),
                ),
              ),
            ],
            Expanded(
              child: TextField(
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 17,
                  color: isLight ? Colors.black : null,
                ),
                onChanged: onChange,
                decoration: InputDecoration(
                  labelText: context.l10n.searchLabel,
                  labelStyle: theme.textTheme.bodyMedium,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.only(
                      left: !arrowHidden ? 12 : 20, right: 15, bottom: 21.6),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
