import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import 'package:mobile_app_skeleton/core/app_scope.dart';
import 'package:mobile_app_skeleton/l10n/l10n_x.dart';
import 'package:mobile_app_skeleton/pages/home/widgets/page_navigation_animation.dart';
import 'package:mobile_app_skeleton/pages/page6/page6_about_page.dart';
import 'package:mobile_app_skeleton/pages/page6/page6_item_entity.dart';
import 'package:mobile_app_skeleton/pages/page6/page6_settings_page.dart';
import 'package:mobile_app_skeleton/pages/page6/page6_usecases.dart';
import 'package:mobile_app_skeleton/widgets/scroll_to_top_button.dart';

class Page6Page extends StatefulWidget {
  final GlobalKey<NavigatorState> mainNavigatorKey;
  final GlobalKey<AnimatedEntryState> pageEntryAnimationKey;
  final GlobalKey<AnimatedExitState> pageExitAnimationKey;

  const Page6Page({
    super.key,
    required this.mainNavigatorKey,
    required this.pageEntryAnimationKey,
    required this.pageExitAnimationKey,
  });

  @override
  State<Page6Page> createState() => _Page6PageState();
}

class _Page6PageState extends State<Page6Page> with AutomaticKeepAliveClientMixin<Page6Page> {
  final ScrollController _scrollController = ScrollController();
  late Page6Usecases _usecases;
  bool _wired = false;
  bool _loading = true;
  List<Page6ItemEntity> _items = const [];

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
    _usecases = AppScope.of(context).services.page6;
    _wired = true;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _usecases.getMenuItems();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  void _open(Page6ItemEntity item) {
    switch (item.id) {
      case 'settings':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Page6SettingsPage()));
        break;
      case 'about':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Page6AboutPage()));
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    String itemTitle(Page6ItemEntity item) {
      switch (item.id) {
        case 'settings':
          return context.l10n.settingsTitle;
        case 'about':
          return context.l10n.aboutTitle;
        default:
          return item.title;
      }
    }

    String itemSubtitle(Page6ItemEntity item) {
      switch (item.id) {
        case 'settings':
          return context.l10n.menuSettingsSubtitle;
        case 'about':
          return context.l10n.menuAboutSubtitle;
        default:
          return item.subtitle;
      }
    }

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
                  child: Text(context.l10n.page6Title, style: theme.textTheme.displayMedium),
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
                          itemCount: _loading ? 2 : _items.length,
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

                            final item = _items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Material(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _open(item),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(itemTitle(item), style: theme.textTheme.headlineSmall),
                                              const SizedBox(height: 6),
                                              Text(itemSubtitle(item), style: theme.textTheme.bodyMedium),
                                            ],
                                          ),
                                        ),
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
