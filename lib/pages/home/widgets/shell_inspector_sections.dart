import 'package:flutter/material.dart';

import 'package:flutter_template/pages/home/page_navigator.dart';

/// Renders page-owned Inspector sections and follows controller focus requests.
class ShellInspectorSections extends StatefulWidget {
  final ShellInspectorController controller;

  const ShellInspectorSections({super.key, required this.controller});

  @override
  State<ShellInspectorSections> createState() => _ShellInspectorSectionsState();
}

class _ShellInspectorSectionsState extends State<ShellInspectorSections> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};
  final Set<String> _expanded = {};
  String? _lastFocusId;

  @override
  void initState() {
    super.initState();
    _syncExpandedSections();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant ShellInspectorSections oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_handleControllerChanged);
    widget.controller.addListener(_handleControllerChanged);
    _syncExpandedSections();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _syncExpandedSections() {
    final sections = widget.controller.sections;
    final ids = sections.map((section) => section.id).toSet();
    _expanded.removeWhere((id) => !ids.contains(id));
    for (final section in sections) {
      if (section.initiallyExpanded) _expanded.add(section.id);
      _sectionKeys.putIfAbsent(section.id, GlobalKey.new);
    }
  }

  void _handleControllerChanged() {
    final focusId = widget.controller.focusedSectionId;
    if (focusId == null || focusId == _lastFocusId) {
      if (mounted) setState(_syncExpandedSections);
      return;
    }
    _lastFocusId = focusId;
    _expanded.add(focusId);
    _syncExpandedSections();
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _sectionKeys[focusId]?.currentContext;
      if (mounted && target != null) Scrollable.ensureVisible(target, alignment: 0.1);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final selection = widget.controller.selectionLabel;
      final sections = widget.controller.sections;
      return ListView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (selection != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Text(selection, style: Theme.of(context).textTheme.labelMedium),
            ),
          ExpansionPanelList(
            expansionCallback: (index, isExpanded) {
              final id = sections[index].id;
              setState(() {
                if (isExpanded) {
                  _expanded.remove(id);
                } else {
                  _expanded.add(id);
                }
              });
            },
            children: [
              for (final section in sections)
                ExpansionPanel(
                  canTapOnHeader: true,
                  isExpanded: _expanded.contains(section.id) || widget.controller.focusedSectionId == section.id,
                  headerBuilder: (context, isExpanded) => Container(
                    key: _sectionKeys.putIfAbsent(section.id, GlobalKey.new),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(section.title, style: Theme.of(context).textTheme.labelMedium),
                  ),
                  body: Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), child: section.builder(context)),
                ),
            ],
          ),
        ],
      );
    },
  );
}
