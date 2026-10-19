import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_template/core/settings.dart';

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

enum ShellViewReusePolicy { never, byRegistration, byInstance }

enum ShellTabLifecycle { restored, opened, activated, deactivated, closing, closed }

typedef ShellViewBuilder = Widget Function(BuildContext context, ShellViewContext view);
typedef ShellDestinationBuilder = Widget Function(
  BuildContext context,
  GlobalKey<NavigatorState> mainNavigatorKey,
  GlobalKey<AnimatedEntryState> entryAnimationKey,
  GlobalKey<AnimatedExitState> exitAnimationKey,
);
typedef ShellTabCloseGuard = FutureOr<bool> Function(BuildContext context, ShellTabPreference tab);
typedef ShellViewActionsBuilder = List<ShellViewAction> Function(BuildContext context, ShellViewContext view);
typedef ShellSectionStatusItemsBuilder = List<ShellStatusItem> Function(BuildContext context);
typedef ShellDestinationAction = FutureOr<void> Function(BuildContext context);
typedef ShellCommandAction = FutureOr<void> Function(BuildContext context);

class ShellViewContext {
  final ShellTabPreference tab;
  final bool isRestored;
  final ValueListenable<ShellTabLifecycle> lifecycle;
  final GlobalKey<NavigatorState> mainNavigatorKey;
  final GlobalKey<AnimatedEntryState> entryAnimationKey;
  final GlobalKey<AnimatedExitState> exitAnimationKey;

  const ShellViewContext({
    required this.tab,
    required this.isRestored,
    required this.lifecycle,
    required this.mainNavigatorKey,
    required this.entryAnimationKey,
    required this.exitAnimationKey,
  });

  String get instanceId => tab.instanceId ?? tab.id;
  Map<String, dynamic> get parameters => tab.parameters;
}

class ShellViewAction {
  final String id;
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const ShellViewAction({required this.id, required this.label, required this.onPressed, this.icon});
}

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
  final bool lockedVisible;
  final String? defaultViewId;
  final Set<String>? allowedViewIds;
  @Deprecated('Move view content to ShellViewRegistration.')
  final ShellDestinationBuilder? builder;
  final String? openViewId;
  final String? commandId;
  final WidgetBuilder? panelBuilder;
  final WidgetBuilder? inspectorBuilder;
  final ShellSectionStatusItemsBuilder? statusItemsBuilder;
  final ShellDestinationAction? onSelected;

  const ShellDestination({
    required this.id,
    required this.title,
    required this.icon,
    this.inactiveIcon,
    this.lockedVisible = false,
    this.defaultViewId,
    this.allowedViewIds,
    @Deprecated('Move view content to ShellViewRegistration.') this.builder,
    this.openViewId,
    this.commandId,
    this.panelBuilder,
    this.inspectorBuilder,
    this.statusItemsBuilder,
    this.onSelected,
  });
}

class ShellViewRegistration {
  final String id;
  final String Function(BuildContext, String instanceId) title;
  @Deprecated('Use viewBuilder for tab-aware view content.')
  final WidgetBuilder? builder;
  final ShellViewBuilder? viewBuilder;
  final String? destinationId;
  final String? contextId;
  final String? moduleId;
  final IconData? icon;
  final String? routePath;
  final ShellViewReusePolicy reusePolicy;
  @Deprecated('Views are independent of destinations.')
  final bool isRoot;
  final bool closeable;
  final ShellTabCloseGuard? onCloseRequested;
  final ShellViewActionsBuilder? toolbarActionsBuilder;
  final ShellViewBuilder? inspectorBuilder;
  final ShellViewBuilder? splitPaneBuilder;
  final ShellStatusProviderFactory? statusProviderFactory;

  const ShellViewRegistration({
    required this.id,
    required this.title,
    @Deprecated('Use viewBuilder for tab-aware view content.') this.builder,
    this.viewBuilder,
    this.destinationId,
    this.contextId,
    this.moduleId,
    this.icon,
    this.routePath,
    this.reusePolicy = ShellViewReusePolicy.never,
    @Deprecated('Views are independent of destinations.') this.isRoot = false,
    this.closeable = true,
    this.onCloseRequested,
    this.toolbarActionsBuilder,
    this.inspectorBuilder,
    this.splitPaneBuilder,
    this.statusProviderFactory,
  });

  bool get hasBuilder => builder != null || viewBuilder != null;

  Widget buildContent(BuildContext context, ShellViewContext view) =>
      viewBuilder?.call(context, view) ?? builder?.call(context) ?? const SizedBox.shrink();
}

class ShellModule {
  final String id;
  final String Function(BuildContext) title;
  final WidgetBuilder builder;

  const ShellModule({required this.id, required this.title, required this.builder});
}

class ShellCommandRegistration {
  final String id;
  final String Function(BuildContext) title;
  final ShellCommandAction run;

  const ShellCommandRegistration({required this.id, required this.title, required this.run});
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
  final List<ShellCommandRegistration> commands;
  final WidgetBuilder? inspectorBuilder;
  final WidgetBuilder? splitPaneBuilder;

  const ShellConfig({
    required this.title,
    required this.destinations,
    this.views = const [],
    this.modules = const [],
    this.contexts = const [],
    this.commands = const [],
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
      defaultViewId: item.name,
      allowedViewIds: item == PageItem.page6 ? {'page6', 'settings'} : {item.name},
    );
  }).toList(),
  views: defaultShellViews(),
);

List<ShellViewRegistration> defaultShellViews() => PageItem.values.map((item) {
  final presentation = _pageItemIcons(item);
  return ShellViewRegistration(
    id: item.name,
    title: (context, instanceId) {
      final title = pageItemPresentation(context, item).title;
      final instanceNumber = int.tryParse(instanceId.split('-').last);
      return instanceNumber == null || instanceNumber == 1 ? title : '$title $instanceNumber';
    },
    destinationId: item.name,
    icon: presentation.activeIcon,
    routePath: '/${item.name}',
    viewBuilder: (context, view) => _buildPageItem(context, view, item),
  );
}).toList();

Widget _buildPageItem(BuildContext context, ShellViewContext view, PageItem item) {
  return switch (item) {
    PageItem.page1 => Page1Page(
      mainNavigatorKey: view.mainNavigatorKey,
      pageEntryAnimationKey: view.entryAnimationKey,
      pageExitAnimationKey: view.exitAnimationKey,
    ),
    PageItem.page2 => Page2Page(
      mainNavigatorKey: view.mainNavigatorKey,
      pageEntryAnimationKey: view.entryAnimationKey,
      pageExitAnimationKey: view.exitAnimationKey,
    ),
    PageItem.page3 => Page3Page(
      pageEntryAnimationKey: view.entryAnimationKey,
      pageExitAnimationKey: view.exitAnimationKey,
    ),
    PageItem.page4 => Page4Page(
      mainNavigatorKey: view.mainNavigatorKey,
      pageEntryAnimationKey: view.entryAnimationKey,
      pageExitAnimationKey: view.exitAnimationKey,
    ),
    PageItem.page5 => Page5Page(
      pageEntryAnimationKey: view.entryAnimationKey,
      pageExitAnimationKey: view.exitAnimationKey,
    ),
    PageItem.page6 => Page6Page(
      mainNavigatorKey: view.mainNavigatorKey,
      pageEntryAnimationKey: view.entryAnimationKey,
      pageExitAnimationKey: view.exitAnimationKey,
    ),
  };
}

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
