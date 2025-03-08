import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/stats/widget/side_bar_stats_overview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract interface class RootScaffold {
  static final stateKey = GlobalKey<ScaffoldState>();

  // Always return true to enable drawer on all screen sizes
  static bool canShowDrawer(BuildContext context) => true;
}

class AdaptiveRootScaffold extends HookConsumerWidget {
  const AdaptiveRootScaffold(this.navigator, {super.key});

  final Widget navigator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    final selectedIndex = getCurrentIndex(context);

    // Removed Logs and About items from the destinations array
    final destinations = [
      NavigationDestination(
        icon: const Icon(FluentIcons.power_20_filled),
        label: t.home.pageTitle,
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.filter_20_filled),
        label: t.proxies.pageTitle,
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.box_edit_20_filled),
        label: t.config.pageTitle,
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.settings_20_filled),
        label: t.settings.pageTitle,
      ),
    ];

    return _CustomAdaptiveScaffold(
      selectedIndex: selectedIndex,
      onSelectedIndexChange: (index) {
        RootScaffold.stateKey.currentState?.closeDrawer();
        switchTab(index, context);
      },
      destinations: destinations,
      drawerDestinationRange: (0, null),
      bottomDestinationRange: (0, 0),
      useBottomSheet: false,
      sidebarTrailing: const Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SideBarStatsOverview(),
        ),
      ),
      body: navigator,
    );
  }
}

class _CustomAdaptiveScaffold extends HookConsumerWidget {
  const _CustomAdaptiveScaffold({
    required this.selectedIndex,
    required this.onSelectedIndexChange,
    required this.destinations,
    required this.drawerDestinationRange,
    required this.bottomDestinationRange,
    this.useBottomSheet = false,
    this.sidebarTrailing,
    required this.body,
  });

  final int selectedIndex;
  final Function(int) onSelectedIndexChange;
  final List<NavigationDestination> destinations;
  final (int, int?) drawerDestinationRange;
  final (int, int?) bottomDestinationRange;
  final bool useBottomSheet;
  final Widget? sidebarTrailing;
  final Widget body;

  List<NavigationDestination> destinationsSlice((int, int?) range) => destinations.sublist(range.$1, range.$2);

  int? selectedWithOffset((int, int?) range) {
    final index = selectedIndex - range.$1;
    return index < 0 || (range.$2 != null && index > (range.$2! - 1)) ? null : index;
  }

  void selectWithOffset(int index, (int, int?) range) => onSelectedIndexChange(index + range.$1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: RootScaffold.stateKey,
      // Always show drawer regardless of screen size
      drawer: Drawer(
        width: (MediaQuery.sizeOf(context).width * 0.88).clamp(1, 304),
        child: Column(
          children: [
            // Add stats to bottom of drawer
            Expanded(
              child: NavigationRail(
                extended: true,
                selectedIndex: selectedWithOffset(drawerDestinationRange),
                destinations: destinationsSlice(drawerDestinationRange).map((dest) => AdaptiveScaffold.toRailDestination(dest)).toList(),
                onDestinationSelected: (index) => selectWithOffset(index, drawerDestinationRange),
              ),
            ),
            // Stats overview at bottom of drawer
            //const SideBarStatsOverview(),
          ],
        ),
      ),
      // Use simple body layout with no primaryNavigation
      body: body,
    );
  }
}
