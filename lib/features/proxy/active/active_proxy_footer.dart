import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/widget/shimmer_skeleton.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/proxy/model/proxy_failure.dart';
import 'package:hiddify/features/stats/notifier/stats_notifier.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ActiveProxyFooter extends HookConsumerWidget {
  const ActiveProxyFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final activeProxy = ref.watch(activeProxyNotifierProvider);
    final ipInfo = ref.watch(ipInfoNotifierProvider);
    final theme = Theme.of(context);

    // Always visible footer with custom styling
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200), // Limit max width
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: theme.brightness == Brightness.dark ? const Color(0xFF140f1a) : const Color(0xFF271f30),
                  offset: const Offset(0, 3),
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                // Refresh button (circle with arrow)
                Padding(
                  padding: const EdgeInsets.only(left: 5, right: 0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ref.read(ipInfoNotifierProvider.notifier).refresh();
                      },
                      customBorder: const CircleBorder(),
                      highlightColor: theme.colorScheme.primary.withOpacity(0.1),
                      splashColor: theme.colorScheme.primary.withOpacity(0.2),
                      child: Ink(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.brightness == Brightness.dark ? const Color(0xFF140f1a) : const Color(0xFF271f30),
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          FluentIcons.arrow_sync_20_regular,
                          color: theme.colorScheme.primary,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),

                // Only show country flag and code instead of full country name
                Expanded(
                  child: switch (activeProxy) {
                    AsyncData() => switch (ipInfo) {
                        AsyncData(value: final info) => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IPCountryFlag(countryCode: info.countryCode),
                              const Gap(8),
                              Flexible(
                                child: Text(
                                  // Show country code instead of full country name
                                  info.countryCode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        AsyncError() => const Center(
                            child: Text(
                              "Check Location",
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        _ => const Center(
                            child: Text(
                              "Checking...",
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                      },
                    _ => const Center(
                        child: Text(
                          "Not connected",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
