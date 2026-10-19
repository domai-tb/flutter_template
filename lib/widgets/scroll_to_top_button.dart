import 'package:flutter/material.dart';

class ScrollToTopButton extends StatefulWidget {
  final ScrollController scrollController;
  final double bottomOffset;
  final double rightOffset;

  const ScrollToTopButton({
    super.key,
    required this.scrollController,
    this.bottomOffset = 20,
    this.rightOffset = 20,
  });

  @override
  State<ScrollToTopButton> createState() => ScrollToTopButtonState();
}

class ScrollToTopButtonState extends State<ScrollToTopButton> {
  final Object _heroTag = Object();
  bool showBacktoTopButton = false;

  void _onScroll() {
    final shouldShow = widget.scrollController.offset > 20;
    if (shouldShow == showBacktoTopButton) return;
    setState(() => showBacktoTopButton = shouldShow);
  }

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.only(
          right: widget.rightOffset,
          bottom: widget.bottomOffset + safeBottom,
        ),
        child: IgnorePointer(
          ignoring: !showBacktoTopButton,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: showBacktoTopButton ? 1 : 0,
            child: FloatingActionButton(
              heroTag: _heroTag,
              onPressed: () {
                widget.scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.fastOutSlowIn,
                );
              },
              backgroundColor: theme.cardColor,
              child: Icon(
                Icons.arrow_upward,
                color: isLight ? Colors.black : const Color.fromRGBO(184, 186, 191, 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
