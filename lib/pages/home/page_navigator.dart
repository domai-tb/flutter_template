import 'package:flutter/material.dart';

import 'package:flutter_template/l10n/l10n_x.dart';
import 'package:flutter_template/pages/home/widgets/page_navigation_animation.dart';
import 'package:flutter_template/pages/page1/page1_page.dart';
import 'package:flutter_template/pages/page2/page2_page.dart';
import 'package:flutter_template/pages/page3/page3_page.dart';
import 'package:flutter_template/pages/page4/page4_page.dart';
import 'package:flutter_template/pages/page5/page5_page.dart';
import 'package:flutter_template/pages/page6/page6_page.dart';

enum PageItem { page1, page2, page3, page4, page5, page6 }

PageItem? pageItemFromId(String id) {
  for (final item in PageItem.values) {
    if (item.name == id) return item;
  }
  return null;
}

List<PageItem> orderedPageItemsFromSettings(List<String> order) {
  final orderedItems = <PageItem>[];
  final seenItems = <PageItem>{};
  for (final id in order) {
    final item = pageItemFromId(id);
    if (item != null && seenItems.add(item)) orderedItems.add(item);
  }
  for (final item in PageItem.values) {
    if (seenItems.add(item)) orderedItems.add(item);
  }
  return orderedItems;
}

Set<PageItem> hiddenPageItemsFromSettings(List<String> hiddenItems) {
  return hiddenItems.map(pageItemFromId).whereType<PageItem>().where((item) => item != PageItem.page6).toSet();
}

List<String> pageItemIds(Iterable<PageItem> items) => items.map((item) => item.name).toList();

class PageItemPresentation {
  final String title;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final double iconPaddingLeft;
  final double iconPaddingRight;

  const PageItemPresentation({
    required this.title,
    required this.activeIcon,
    required this.inactiveIcon,
    this.iconPaddingLeft = 10,
    this.iconPaddingRight = 10,
  });
}

PageItemPresentation pageItemPresentation(BuildContext context, PageItem item) {
  switch (item) {
    case PageItem.page1:
      return PageItemPresentation(
        title: context.l10n.page1Title,
        activeIcon: Icons.home,
        inactiveIcon: Icons.home_outlined,
        iconPaddingLeft: 0,
      );
    case PageItem.page2:
      return PageItemPresentation(
        title: context.l10n.page2Title,
        activeIcon: Icons.calendar_month,
        inactiveIcon: Icons.calendar_month_outlined,
        iconPaddingLeft: 14,
      );
    case PageItem.page3:
      return PageItemPresentation(
        title: context.l10n.page3Title,
        activeIcon: Icons.map,
        inactiveIcon: Icons.map_outlined,
      );
    case PageItem.page4:
      return PageItemPresentation(
        title: context.l10n.page4Title,
        activeIcon: Icons.restaurant,
        inactiveIcon: Icons.restaurant_outlined,
      );
    case PageItem.page5:
      return PageItemPresentation(
        title: context.l10n.page5Title,
        activeIcon: Icons.account_balance_wallet,
        inactiveIcon: Icons.account_balance_wallet_outlined,
      );
    case PageItem.page6:
      return PageItemPresentation(
        title: context.l10n.page6Title,
        activeIcon: Icons.more_horiz,
        inactiveIcon: Icons.more_horiz,
        iconPaddingLeft: 5,
        iconPaddingRight: 0,
      );
  }
}

typedef ShellDestinationBuilder = Widget Function(
  BuildContext context,
  GlobalKey<NavigatorState> mainNavigatorKey,
  GlobalKey<AnimatedEntryState> entryAnimationKey,
  GlobalKey<AnimatedExitState> exitAnimationKey,
);

enum ShellStatusSeverity { normal, success, warning, error }

class ShellStatusItem {
  final String id;
  final String label;
  final IconData? icon;
  final int priority;
  final ShellStatusSeverity severity;
  final String? tooltip;
  final VoidCallback? onTap;
  final bool Function()? isVisible;

  const ShellStatusItem({
    required this.id,
    required this.label,
    this.icon,
    this.priority = 0,
    this.severity = ShellStatusSeverity.normal,
    this.tooltip,
    this.onTap,
    this.isVisible,
  });
}

abstract class ShellStatusProvider extends ChangeNotifier {
  List<ShellStatusItem> get items;
}

typedef ShellStatusProviderFactory = ShellStatusProvider Function(String instanceId);

class ShellDestination {
  final String id;
  final String Function(BuildContext) title;
  final IconData icon;
  final IconData? inactiveIcon;
  final ShellDestinationBuilder builder;
  final bool lockedVisible;

  const ShellDestination({
    required this.id,
    required this.title,
    required this.icon,
    required this.builder,
    this.inactiveIcon,
    this.lockedVisible = false,
  });
}

class ShellViewRegistration {
  final String id;
  final String Function(BuildContext, String instanceId) title;
  final WidgetBuilder? builder;
  final String? destinationId;
  final String? contextId;
  final String? moduleId;
  final IconData? icon;
  final bool isRoot;
  final bool closeable;
  final WidgetBuilder? inspectorBuilder;
  final WidgetBuilder? splitPaneBuilder;
  final ShellStatusProviderFactory? statusProviderFactory;

  const ShellViewRegistration({
    required this.id,
    required this.title,
    this.builder,
    this.destinationId,
    this.contextId,
    this.moduleId,
    this.icon,
    this.isRoot = false,
    this.closeable = true,
    this.inspectorBuilder,
    this.splitPaneBuilder,
    this.statusProviderFactory,
  });
}

class ShellModule {
  final String id;
  final String Function(BuildContext) title;
  final WidgetBuilder builder;

  const ShellModule({required this.id, required this.title, required this.builder});
}

class ShellContext {
  final String id;
  final String Function(BuildContext) title;
  final List<ShellModule> modules;

  const ShellContext({required this.id, required this.title, required this.modules});
}

class ShellConfig {
  final String Function(BuildContext) title;
  final List<ShellDestination> destinations;
  final List<ShellViewRegistration> views;
  final List<ShellModule> modules;
  final List<ShellContext> contexts;
  final WidgetBuilder? inspectorBuilder;
  final WidgetBuilder? splitPaneBuilder;

  const ShellConfig({
    required this.title,
    required this.destinations,
    this.views = const [],
    this.modules = const [],
    this.contexts = const [],
    this.inspectorBuilder,
    this.splitPaneBuilder,
  });
}

enum ShellSlotState { content, empty, loading, error, unavailable }

class ShellContentSlot extends StatelessWidget {
  final ShellSlotState state;
  final Widget? child;
  final String? message;
  final VoidCallback? onRetry;

  const ShellContentSlot({super.key, required this.state, this.child, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (state == ShellSlotState.content && child != null) return child!;
    final text = switch (state) {
      ShellSlotState.content || ShellSlotState.empty => message ?? context.l10n.shellPlaceholderBody,
      ShellSlotState.loading => message ?? context.l10n.loading,
      ShellSlotState.error => message ?? context.l10n.generalFailureMessage,
      ShellSlotState.unavailable => message ?? context.l10n.shellMissingView,
    };
    return Semantics(
      liveRegion: state == ShellSlotState.error,
      child: Center(
        child: state == ShellSlotState.loading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (message != null) ...[const SizedBox(height: 12), Text(text, textAlign: TextAlign.center)],
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(text, textAlign: TextAlign.center),
                  if (state == ShellSlotState.error && onRetry != null) ...[
                    const SizedBox(height: 12),
                    TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
                  ],
                ],
              ),
      ),
    );
  }
}

ShellConfig defaultShellConfig() => ShellConfig(
  title: (context) => context.l10n.appTitle,
  destinations: PageItem.values.map((item) {
    final presentation = _pageItemIcons(item);
    return ShellDestination(
      id: item.name,
      title: (context) => pageItemPresentation(context, item).title,
      icon: presentation.activeIcon,
      inactiveIcon: presentation.inactiveIcon,
      lockedVisible: item == PageItem.page6,
      builder: (context, mainKey, entryKey, exitKey) {
        switch (item) {
          case PageItem.page1:
            return Page1Page(mainNavigatorKey: mainKey, pageEntryAnimationKey: entryKey, pageExitAnimationKey: exitKey);
          case PageItem.page2:
            return Page2Page(mainNavigatorKey: mainKey, pageEntryAnimationKey: entryKey, pageExitAnimationKey: exitKey);
          case PageItem.page3:
            return Page3Page(pageEntryAnimationKey: entryKey, pageExitAnimationKey: exitKey);
          case PageItem.page4:
            return Page4Page(mainNavigatorKey: mainKey, pageEntryAnimationKey: entryKey, pageExitAnimationKey: exitKey);
          case PageItem.page5:
            return Page5Page(pageEntryAnimationKey: entryKey, pageExitAnimationKey: exitKey);
          case PageItem.page6:
            return Page6Page(mainNavigatorKey: mainKey, pageEntryAnimationKey: entryKey, pageExitAnimationKey: exitKey);
        }
      },
    );
  }).toList(),
  views: defaultShellViews(),
);

List<ShellViewRegistration> defaultShellViews() => const [];

PageItemPresentation _pageItemIcons(PageItem item) {
  switch (item) {
    case PageItem.page1:
      return const PageItemPresentation(title: '', activeIcon: Icons.home, inactiveIcon: Icons.home_outlined);
    case PageItem.page2:
      return const PageItemPresentation(
        title: '',
        activeIcon: Icons.calendar_month,
        inactiveIcon: Icons.calendar_month_outlined,
      );
    case PageItem.page3:
      return const PageItemPresentation(title: '', activeIcon: Icons.map, inactiveIcon: Icons.map_outlined);
    case PageItem.page4:
      return const PageItemPresentation(
        title: '',
        activeIcon: Icons.restaurant,
        inactiveIcon: Icons.restaurant_outlined,
      );
    case PageItem.page5:
      return const PageItemPresentation(
        title: '',
        activeIcon: Icons.account_balance_wallet,
        inactiveIcon: Icons.account_balance_wallet_outlined,
      );
    case PageItem.page6:
      return const PageItemPresentation(title: '', activeIcon: Icons.more_horiz, inactiveIcon: Icons.more_horiz);
  }
}

class PageNavigatorRoutes {
  static const String root = '/';
  static const String detail = '/detail';
}

class NavBarNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> mainNavigatorKey;
  final GlobalKey<NavigatorState> navigatorKey;
  final ShellDestination destination;
  final GlobalKey<AnimatedEntryState> pageEntryAnimationKey;
  final GlobalKey<AnimatedExitState> pageExitAnimationKey;

  const NavBarNavigator({
    super.key,
    required this.mainNavigatorKey,
    required this.navigatorKey,
    required this.destination,
    required this.pageEntryAnimationKey,
    required this.pageExitAnimationKey,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      initialRoute: PageNavigatorRoutes.root,
      onGenerateRoute: (routeSettings) => MaterialPageRoute<void>(
        builder: (context) {
          if (routeSettings.name != PageNavigatorRoutes.root) {
            return Center(child: Text(context.l10n.shellMissingRoute));
          }
          try {
            return destination.builder(context, mainNavigatorKey, pageEntryAnimationKey, pageExitAnimationKey);
          } catch (error) {
            return ShellContentSlot(state: ShellSlotState.error, message: context.l10n.shellContentError('$error'));
          }
        },
      ),
    );
  }
}
