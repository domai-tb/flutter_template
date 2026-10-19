import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

import 'package:flutter/material.dart';

import 'package:flutter_template/core/app_scope.dart';
import 'package:flutter_template/l10n/l10n_x.dart';
import 'package:flutter_template/pages/home/page_navigator.dart';
import 'package:flutter_template/pages/home/widgets/page_navigation_animation.dart';
import 'package:flutter_template/pages/page1/page1_detail_page.dart';
import 'package:flutter_template/pages/page1/page1_item_entity.dart';
import 'package:flutter_template/pages/page1/page1_usecases.dart';
import 'package:flutter_template/widgets/app_icon_button.dart';
import 'package:flutter_template/widgets/app_search_bar.dart';
import 'package:flutter_template/widgets/scroll_to_top_button.dart';

class Page1Page extends StatefulWidget {
  final GlobalKey<NavigatorState> mainNavigatorKey;
  final GlobalKey<AnimatedEntryState> pageEntryAnimationKey;
  final GlobalKey<AnimatedExitState> pageExitAnimationKey;
  final ShellViewContext view;

  const Page1Page({
    super.key,
    required this.mainNavigatorKey,
    required this.pageEntryAnimationKey,
    required this.pageExitAnimationKey,
    required this.view,
  });

  @override
  State<Page1Page> createState() => _Page1PageState();
}

class _Page1PageState extends State<Page1Page> with AutomaticKeepAliveClientMixin<Page1Page> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final ScrollController _scrollController = ScrollController();

  late Page1Usecases _usecases;
  late ShellViewContext _view;
  bool _wired = false;

  List<Page1ItemEntity> _items = const [];
  bool _loading = true;
  bool _showSearch = false;
  String _query = '';
  String _selectedNavigationId = 'page1.overview';
  Page1ItemEntity? _selectedItem;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_wired) return;
    _usecases = AppScope.of(context).services.page1;
    _view = widget.view;
    _wired = true;
    _registerShellNavigation();
    _view.rightSidebar.setSelection(context.l10n.page1Title);
    _view.rightSidebar.setSections([
      ShellRightSidebarSection(
        id: 'page1.selected-item',
        title: context.l10n.selectedItem,
        builder: (context) {
          final item = _selectedItem;
          return Padding(
            padding: const EdgeInsets.all(12),
            child: item == null
                ? Text(context.l10n.selectItemForDetails)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 6),
                      Text(item.subtitle, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
          );
        },
      ),
    ]);
    _load();
  }

  void _registerShellNavigation() {
    const rootId = 'page1.root';
    final overview = ShellNavigationNode(
      id: 'page1.overview',
      label: context.l10n.page1Overview,
      parentId: rootId,
      icon: Icons.dashboard_outlined,
      onActivate: () => _selectNavigation('page1.overview'),
    );
    final allItems = ShellNavigationNode(
      id: 'page1.all-items',
      label: context.l10n.page1AllItems,
      parentId: 'page1.items',
      onActivate: () => _selectNavigation('page1.all-items'),
    );
    final recentItems = ShellNavigationNode(
      id: 'page1.recent-items',
      label: context.l10n.page1RecentItems,
      parentId: 'page1.items',
      onActivate: () => _selectNavigation('page1.recent-items'),
    );
    final items = ShellNavigationNode(
      id: 'page1.items',
      label: context.l10n.page1Items,
      parentId: rootId,
      icon: Icons.list_alt_outlined,
      children: [allItems, recentItems],
    );
    final summary = ShellNavigationNode(
      id: 'page1.summary',
      label: context.l10n.page1Summary,
      parentId: 'page1.reports',
      onActivate: () => _selectNavigation('page1.summary'),
    );
    final reports = ShellNavigationNode(
      id: 'page1.reports',
      label: context.l10n.page1Reports,
      parentId: rootId,
      icon: Icons.assessment_outlined,
      children: [summary],
    );
    final root = ShellNavigationNode(
      id: rootId,
      label: context.l10n.page1Title,
      icon: Icons.home_outlined,
      children: [overview, items, reports],
    );
    _view.breadcrumbs.registerNodes([root, overview, items, allItems, recentItems, reports, summary]);
    final restoredPath = _view.breadcrumbs.activePath;
    if (restoredPath.isNotEmpty) {
      _selectedNavigationId = restoredPath.last.id;
    } else {
      _view.breadcrumbs.setPath([root, overview]);
    }
  }

  void _selectNavigation(String id) {
    if (!mounted || _selectedNavigationId == id) return;
    setState(() => _selectedNavigationId = id);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _usecases.getItems(query: _query);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  void _openItem(Page1ItemEntity item) {
    setState(() => _selectedItem = item);
    _view.rightSidebar.setSelection(item.title);
    _view.rightSidebar.focusSection('page1.selected-item');
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => Page1DetailPage(item: item)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final visibleItems = _selectedNavigationId == 'page1.recent-items' ? _items.take(5).toList() : _items;

    return AnimatedExit(
      key: widget.pageExitAnimationKey,
      child: AnimatedEntry(
        key: widget.pageEntryAnimationKey,
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
                  child: Row(
                    children: [
                      Expanded(child: Text(context.l10n.page1Title, style: theme.textTheme.displayMedium)),
                      AppIconButton(
                        icon: _showSearch ? Icons.arrow_back : Icons.search,
                        onTap: () {
                          setState(() {
                            _showSearch = !_showSearch;
                            if (!_showSearch) _query = '';
                          });
                          _load();
                        },
                        transparent: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (_showSearch)
                  AppSearchBar(
                    arrowHidden: true,
                    onBack: () {},
                    onChange: (q) {
                      setState(() => _query = q);
                      _load();
                    },
                  ),
                const SizedBox(height: 10),
                Expanded(
                  child: _selectedNavigationId == 'page1.summary'
                      ? Center(child: Text(context.l10n.page1SummaryDescription(_items.length)))
                      : Stack(
                          children: [
                            RefreshIndicator(
                              key: _refreshIndicatorKey,
                              onRefresh: _load,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.only(
                                  bottom: defaultTargetPlatform == TargetPlatform.iOS ? 110 : 90,
                                  top: 10,
                                ),
                                itemCount: _loading ? 6 : visibleItems.length,
                                itemBuilder: (context, index) {
                                  if (_loading) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      child: Container(
                                        height: 72,
                                        decoration: BoxDecoration(
                                          color: theme.cardColor,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    );
                                  }

                                  final item = visibleItems[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    child: Material(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () => _openItem(item),
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(item.title, style: theme.textTheme.headlineSmall),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      item.subtitle,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: theme.textTheme.bodyMedium,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              const Icon(Icons.chevron_right),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            ScrollToTopButton(
                              scrollController: _scrollController,
                              bottomOffset: defaultTargetPlatform == TargetPlatform.iOS ? 110 : 90,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
