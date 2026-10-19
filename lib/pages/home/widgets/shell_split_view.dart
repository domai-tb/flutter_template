import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_template/core/themes.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';

/// Hosts the primary page and the secondary panes requested by its tab.
class ShellSplitView extends StatelessWidget {
  final Widget primary;
  final ShellViewContext view;
  final ShellWorkspaceController workspace;

  const ShellSplitView({super.key, required this.primary, required this.view, required this.workspace});

  @override
  Widget build(BuildContext context) {
    final panes = workspace.panes;
    if (!workspace.isSplitOpen || panes.isEmpty) return primary;

    final contents = <Widget>[
      KeyedSubtree(key: const ValueKey('shell-pane-primary'), child: primary),
      for (final pane in panes)
        KeyedSubtree(key: ValueKey('shell-pane-${pane.id}'), child: pane.builder(context, view)),
    ];
    final ids = ['primary', for (final pane in panes) pane.id];
    final titles = ['Primary', for (final pane in panes) pane.title];

    return LayoutBuilder(
      builder: (context, constraints) {
        const handleWidth = 12.0;
        final availableWidth = constraints.maxWidth - handleWidth * (contents.length - 1);
        final minWidths = [240.0, for (final pane in panes) pane.minWidth];
        final canShowColumns = availableWidth >= minWidths.fold<double>(0, (sum, width) => sum + width);
        if (!canShowColumns) {
          final selectedId = workspace.collapsedPaneId ?? 'primary';
          final selectedIndex = ids.indexOf(selectedId).clamp(0, ids.length - 1);
          return Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: DropdownButton<String>(
                  key: const ValueKey('shell-collapsed-pane-selector'),
                  value: selectedId,
                  items: [
                    for (var index = 0; index < titles.length; index++)
                      DropdownMenuItem(value: ids[index], child: Text(titles[index])),
                  ],
                  onChanged: (id) => id == null ? null : workspace.selectCollapsedPane(id),
                ),
              ),
              Expanded(
                child: IndexedStack(index: selectedIndex, children: contents),
              ),
            ],
          );
        }

        final weights = _normalizedWeights(workspace.weights, contents.length);
        return Row(
          children: [
            for (var index = 0; index < contents.length; index++) ...[
              Expanded(flex: (weights[index] * 10000).round().clamp(1, 10000), child: contents[index]),
              if (index < contents.length - 1)
                _SplitHandle(
                  index: index,
                  width: availableWidth,
                  weights: weights,
                  minWidths: minWidths,
                  handleWidth: handleWidth,
                  onResize: workspace.setWeights,
                ),
            ],
          ],
        );
      },
    );
  }

  List<double> _normalizedWeights(List<double> source, int count) {
    if (source.length != count || source.any((weight) => !weight.isFinite || weight <= 0)) {
      return List<double>.filled(count, 1 / count);
    }
    final total = source.fold<double>(0, (sum, weight) => sum + weight);
    return source.map((weight) => weight / total).toList(growable: false);
  }
}

class _SplitHandle extends StatelessWidget {
  final int index;
  final double width;
  final double handleWidth;
  final List<double> weights;
  final List<double> minWidths;
  final void Function(List<double>, {required bool persist}) onResize;

  const _SplitHandle({
    required this.index,
    required this.width,
    required this.handleWidth,
    required this.weights,
    required this.minWidths,
    required this.onResize,
  });

  void _resize(double delta) {
    if (width <= 0) return;
    final next = List<double>.of(weights);
    final lower = minWidths[index] / width;
    final upper = 1 - minWidths[index + 1] / width;
    final left = (next[index] + delta / width).clamp(lower, upper);
    final moved = left - next[index];
    next[index] = left;
    next[index + 1] -= moved;
    onResize(next, persist: false);
  }

  void _persist() => onResize(weights, persist: true);

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppShellTokens>();
    return Semantics(
      button: true,
      label: 'Resize workspace panes',
      value: '${(weights[index] * 100).round()}%',
      increasedValue: '${((weights[index] + 0.05).clamp(0.05, 0.95) * 100).round()}%',
      decreasedValue: '${((weights[index] - 0.05).clamp(0.05, 0.95) * 100).round()}%',
      onIncrease: () {
        _resize(width * 0.05);
        _persist();
      },
      onDecrease: () {
        _resize(-width * 0.05);
        _persist();
      },
      child: Focus(
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _resize(-16);
            _persist();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _resize(16);
            _persist();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          key: ValueKey('shell-split-handle-$index'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) => _resize(details.delta.dx),
          onHorizontalDragEnd: (_) => _persist(),
          onDoubleTap: () {
            final next = List<double>.of(weights);
            final pair = next[index] + next[index + 1];
            next[index] = pair / 2;
            next[index + 1] = pair / 2;
            onResize(next, persist: true);
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            child: SizedBox(
              width: handleWidth,
              child: Center(
                child: Container(
                  width: 1,
                  color: tokens?.border ?? Theme.of(context).dividerColor,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
