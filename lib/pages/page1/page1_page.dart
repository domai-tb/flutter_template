import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import 'package:mobile_app_skeleton/core/app_scope.dart';
import 'package:mobile_app_skeleton/l10n/l10n_x.dart';
import 'package:mobile_app_skeleton/pages/home/widgets/page_navigation_animation.dart';
import 'package:mobile_app_skeleton/pages/page1/page1_detail_page.dart';
import 'package:mobile_app_skeleton/pages/page1/page1_item_entity.dart';
import 'package:mobile_app_skeleton/pages/page1/page1_usecases.dart';
import 'package:mobile_app_skeleton/widgets/app_icon_button.dart';
import 'package:mobile_app_skeleton/widgets/app_search_bar.dart';
import 'package:mobile_app_skeleton/widgets/scroll_to_top_button.dart';

class Page1Page extends StatefulWidget {
  final GlobalKey<NavigatorState> mainNavigatorKey;
  final GlobalKey<AnimatedEntryState> pageEntryAnimationKey;
  final GlobalKey<AnimatedExitState> pageExitAnimationKey;

  const Page1Page({
    super.key,
    required this.mainNavigatorKey,
    required this.pageEntryAnimationKey,
    required this.pageExitAnimationKey,
  });

  @override
  State<Page1Page> createState() => _Page1PageState();
}

class _Page1PageState extends State<Page1Page>
    with AutomaticKeepAliveClientMixin<Page1Page> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final ScrollController _scrollController = ScrollController();

  late Page1Usecases _usecases;
  bool _wired = false;

  List<Page1ItemEntity> _items = const [];
  bool _loading = true;
  bool _showSearch = false;
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_wired) return;
    _usecases = AppScope.of(context).services.page1;
    _wired = true;
    _load();
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => Page1DetailPage(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);

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
                      Expanded(
                        child: Text(
                          context.l10n.page1Title,
                          style: theme.textTheme.displayMedium,
                        ),
                      ),
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
                  child: Stack(
                    children: [
                      RefreshIndicator(
                        key: _refreshIndicatorKey,
                        onRefresh: _load,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.only(
                              bottom: Platform.isIOS ? 110 : 90, top: 10),
                          itemCount: _loading ? 6 : _items.length,
                          itemBuilder: (context, index) {
                            if (_loading) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 8),
                                child: Container(
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              );
                            }

                            final item = _items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                style: theme
                                                    .textTheme.headlineSmall,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                item.subtitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    theme.textTheme.bodyMedium,
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
                        bottomOffset: Platform.isIOS ? 110 : 90,
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
