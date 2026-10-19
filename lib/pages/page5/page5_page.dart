import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

import 'package:flutter/material.dart';

import 'package:flutter_template/core/app_scope.dart';
import 'package:flutter_template/l10n/l10n_x.dart';
import 'package:flutter_template/pages/home/widgets/page_navigation_animation.dart';
import 'package:flutter_template/pages/page5/page5_item_entity.dart';
import 'package:flutter_template/pages/page5/page5_usecases.dart';
import 'package:flutter_template/widgets/app_button.dart';
import 'package:flutter_template/widgets/scroll_to_top_button.dart';

class Page5Page extends StatefulWidget {
  final GlobalKey<AnimatedEntryState> pageEntryAnimationKey;
  final GlobalKey<AnimatedExitState> pageExitAnimationKey;

  const Page5Page({
    super.key,
    required this.pageEntryAnimationKey,
    required this.pageExitAnimationKey,
  });

  @override
  State<Page5Page> createState() => _Page5PageState();
}

class _Page5PageState extends State<Page5Page>
    with AutomaticKeepAliveClientMixin<Page5Page> {
  final ScrollController _scrollController = ScrollController();
  late Page5Usecases _usecases;
  bool _wired = false;
  bool _loading = true;
  List<Page5ItemEntity> _cards = const [];

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_wired) return;
    _usecases = AppScope.of(context).services.page5;
    _wired = true;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cards = await _usecases.getItems();
    if (!mounted) return;
    setState(() {
      _cards = cards;
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
            child: RefreshIndicator(
              onRefresh: _load,
              child: Stack(
                children: [
                  ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                    children: [
                      Text(context.l10n.page5Title,
                          style: theme.textTheme.displayMedium),
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.walletPlaceholderBody,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      if (_loading)
                        Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                        )
                      else
                        ..._cards.map(
                          (c) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(c.title,
                                          style: theme.textTheme.headlineSmall),
                                      const SizedBox(height: 6),
                                      Text(c.value,
                                          style: theme.textTheme.bodyMedium),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.credit_card),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      AppButton(
                        text: context.l10n.primaryAction,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(context.l10n.primaryActionSnack)),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      AppButton.light(
                        text: context.l10n.secondaryAction,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text(context.l10n.secondaryActionSnack)),
                          );
                        },
                      ),
                    ],
                  ),
                  ScrollToTopButton(
                    scrollController: _scrollController,
                    bottomOffset: defaultTargetPlatform == TargetPlatform.iOS ? 110 : 90,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
