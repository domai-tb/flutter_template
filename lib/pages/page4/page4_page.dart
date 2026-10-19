import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import 'package:mobile_app_skeleton/core/app_scope.dart';
import 'package:mobile_app_skeleton/l10n/l10n_x.dart';
import 'package:mobile_app_skeleton/pages/home/widgets/page_navigation_animation.dart';
import 'package:mobile_app_skeleton/pages/page4/page4_item_entity.dart';
import 'package:mobile_app_skeleton/pages/page4/page4_usecases.dart';
import 'package:mobile_app_skeleton/widgets/scroll_to_top_button.dart';

class Page4Page extends StatefulWidget {
  final GlobalKey<NavigatorState> mainNavigatorKey;
  final GlobalKey<AnimatedEntryState> pageEntryAnimationKey;
  final GlobalKey<AnimatedExitState> pageExitAnimationKey;

  const Page4Page({
    super.key,
    required this.mainNavigatorKey,
    required this.pageEntryAnimationKey,
    required this.pageExitAnimationKey,
  });

  @override
  State<Page4Page> createState() => _Page4PageState();
}

class _Page4PageState extends State<Page4Page> with AutomaticKeepAliveClientMixin<Page4Page> {
  final ScrollController _scrollController = ScrollController();
  late Page4Usecases _usecases;
  bool _wired = false;
  bool _loading = true;
  List<Page4ItemEntity> _items = const [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_wired) return;
    _usecases = AppScope.of(context).services.page4;
    _wired = true;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _usecases.getItems();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
                  child: Text(context.l10n.page4Title, style: theme.textTheme.displayMedium),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.only(bottom: Platform.isIOS ? 110 : 90, top: 10),
                          itemCount: _loading ? 4 : _items.length,
                          itemBuilder: (context, index) {
                            if (_loading) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                child: Container(
                                  height: 92,
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              );
                            }

                            final item = _items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.title, style: theme.textTheme.headlineSmall),
                                          const SizedBox(height: 6),
                                          Text(item.description, style: theme.textTheme.bodyMedium),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '\$${item.price.toStringAsFixed(2)}',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ],
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
