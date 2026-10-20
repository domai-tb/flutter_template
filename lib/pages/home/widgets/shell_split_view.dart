import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_template/core/themes.dart';
import 'package:flutter_template/l10n/l10n_x.dart';
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
        final handleWidth = AppTheme.metrics(context, phone: false).splitHandleWidth;
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

        final weights = _weightsWithinMinimums(workspace.weights, minWidths, availableWidth);
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
                  onPersist: workspace.persistLayout,
                ),
            ],
          ],
        );
      },
    );
  }

  List<double> _weightsWithinMinimums(List<double> source, List<double> minWidths, double width) {
    final count = minWidths.length;
    final valid = source.length == count && source.every((weight) => weight.isFinite && weight > 0)
        ? source
        : List<double>.filled(count, 1);
    final total = valid.fold<double>(0, (sum, weight) => sum + weight);
    final weights = valid.map((weight) => weight / total).toList();
    final fixed = <int>{};

    for (var pass = 0; pass < count; pass++) {
      final underMinimum = [
        for (var index = 0; index < count; index++)
          if (!fixed.contains(index) && weights[index] * width < minWidths[index]) index,
      ];
      if (underMinimum.isEmpty) break;
      fixed.addAll(underMinimum);
      for (final index in underMinimum) {
        weights[index] = minWidths[index] / width;
      }
      final flexible = [
        for (var index = 0; index < count; index++)
          if (!fixed.contains(index)) index,
      ];
      if (flexible.isEmpty) break;
      final availableWeight = 1 - fixed.fold<double>(0, (sum, index) => sum + weights[index]);
      final flexibleWeight = flexible.fold<double>(0, (sum, index) => sum + weights[index]);
      for (final index in flexible) {
        weights[index] = flexibleWeight == 0
            ? availableWeight / flexible.length
            : weights[index] / flexibleWeight * availableWeight;
      }
    }
    return weights;
  }
}

class _SplitHandle extends StatelessWidget {
  final int index;
  final double width;
  final double handleWidth;
  final List<double> weights;
  final List<double> minWidths;
  final void Function(List<double>, {required bool persist}) onResize;
  final VoidCallback onPersist;

  const _SplitHandle({
    required this.index,
    required this.width,
    required this.handleWidth,
    required this.weights,
    required this.minWidths,
    required this.onResize,
    required this.onPersist,
  });

  void _resize(double delta) {
    if (width <= 0) return;
    final next = List<double>.of(weights);
    final pair = next[index] + next[index + 1];
    final lower = minWidths[index] / width;
    final upper = pair - minWidths[index + 1] / width;
    if (lower > upper) return;
    final left = (next[index] + delta / width).clamp(lower, upper);
    final moved = left - next[index];
    next[index] = left;
    next[index + 1] -= moved;
    onResize(next, persist: false);
  }

  void _persist() => onPersist();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppShellTokens>();
    return Semantics(
      button: true,
      label: context.l10n.resizeSplitPane,
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
