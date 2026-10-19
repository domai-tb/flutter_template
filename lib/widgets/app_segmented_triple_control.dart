import 'package:flutter/material.dart';

/// A three-option control that follows the selection supplied by its parent.
class AppSegmentedTripleControl extends StatelessWidget {
  final String leftTitle;
  final String centerTitle;
  final String rightTitle;
  final void Function(int) onChanged;
  final int initialSelection;

  const AppSegmentedTripleControl({
    super.key,
    required this.leftTitle,
    required this.centerTitle,
    required this.rightTitle,
    required this.onChanged,
    this.initialSelection = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<int>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: 0, label: Text(leftTitle)),
          ButtonSegment(value: 1, label: Text(centerTitle)),
          ButtonSegment(value: 2, label: Text(rightTitle)),
        ],
        selected: {initialSelection.clamp(0, 2)},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}
