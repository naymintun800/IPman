import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/features/proxy/widget/proxy_tile.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProxiesModal extends HookConsumerWidget {
  const ProxiesModal({this.scrollController, super.key});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final asyncProxies = ref.watch(proxiesOverviewNotifierProvider);
    final notifier = ref.watch(proxiesOverviewNotifierProvider.notifier);

    final selectActiveProxyMutation = useMutation(
      initialOnFailure: (error) => CustomToast.error("Error").show(context),
    );

    // Get screen height and limit modal height
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.6; // Limit to 60% of screen height

    return Container(
      height: modalHeight, // Constrain the height
      child: switch (asyncProxies) {
        AsyncData(value: final groups) when groups.isEmpty => Center(
            child: Text(t.proxies.emptyProxiesMsg),
          ),
        AsyncData(value: final groups) => Column(
            children: [
              // Limited height list view
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 16), // Reduced padding
                  itemCount: groups.first.items.length,
                  itemBuilder: (context, index) {
                    final group = groups.first;
                    final proxy = group.items[index];
                    return ProxyTile(
                      proxy,
                      selected: group.selected == proxy.tag,
                      onSelect: () async {
                        if (selectActiveProxyMutation.state.isInProgress) {
                          return;
                        }
                        selectActiveProxyMutation.setFuture(
                          notifier.changeProxy(group.tag, proxy.tag),
                        );
                      },
                    );
                  },
                ),
              ),

              // Delay test button - positioned directly below list
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: FloatingActionButton.extended(
                  onPressed: () => notifier.urlTest(groups.first.tag),
                  icon: const Icon(FluentIcons.flash_24_filled),
                  label: Text(t.proxies.delayTestTooltip),
                ),
              ),
            ],
          ),
        AsyncError() => Center(
            child: Text(t.proxies.emptyProxiesMsg),
          ),
        _ => const Center(
            child: CircularProgressIndicator(),
          ),
      },
    );
  }
}
