import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShellDesktopTab extends StatefulWidget {
  final String title;
  final IconData? icon;
  final bool selected;
  final bool closable;
  final VoidCallback onSelect;
  final VoidCallback onClose;
  final ValueChanged<Offset> onContextMenu;

  const ShellDesktopTab({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.closable,
    required this.onSelect,
    required this.onClose,
    required this.onContextMenu,
  });

  @override
  State<ShellDesktopTab> createState() => _ShellDesktopTabState();
}

class _ShellDesktopTabState extends State<ShellDesktopTab> {
  bool _hovered = false;
  bool _focused = false;

  void _showContextMenu() {
    final box = context.findRenderObject() as RenderBox?;
    widget.onContextMenu(box?.localToGlobal(Offset(0, box.size.height)) ?? Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showClose = widget.closable && (widget.selected || _hovered || _focused);
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.title,
      child: Tooltip(
        message: widget.title,
        child: Focus(
          onFocusChange: (value) => setState(() => _focused = value),
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.contextMenu ||
                    (event.logicalKey == LogicalKeyboardKey.f10 && HardwareKeyboard.instance.isShiftPressed))) {
              _showContextMenu();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: Listener(
              onPointerDown: (event) {
                if (event.kind == PointerDeviceKind.mouse &&
                    event.buttons & kMiddleMouseButton != 0 &&
                    widget.closable) {
                  widget.onClose();
                }
              },
              child: GestureDetector(
                onSecondaryTapDown: (details) => widget.onContextMenu(details.globalPosition),
                child: Material(
                  color: widget.selected
                      ? theme.colorScheme.surface
                      : _hovered
                      ? theme.colorScheme.surfaceContainerHighest
                      : Colors.transparent,
                  child: InkWell(
                    onTap: widget.onSelect,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 88, maxWidth: 190),
                      height: 34,
                      padding: const EdgeInsets.only(left: 9, right: 4),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: widget.selected ? theme.colorScheme.primary : Colors.transparent,
                            width: 2,
                          ),
                          right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: widget.selected
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (showClose)
                            IconButton(
                              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                              onPressed: widget.onClose,
                              icon: const Icon(Icons.close, size: 14),
                              style: IconButton.styleFrom(
                                minimumSize: const Size.square(26),
                                maximumSize: const Size.square(26),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
