//import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/routes.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ActiveProxyFooter extends HookConsumerWidget {
  const ActiveProxyFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final activeProxy = ref.watch(activeProxyNotifierProvider);
    final ipInfo = ref.watch(ipInfoNotifierProvider);
    final theme = Theme.of(context);

    // Use platform detection for better sizing
    final isDesktop = PlatformUtils.isDesktop;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 8 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 180 : 200),
          child: GestureDetector(
            onTap: () {
              // Navigate to proxies modal (not the refresh button)
              const ProxiesModalRoute().push(context);
            },
            child: Container(
              height: isDesktop ? 60 : 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: theme.brightness == Brightness.dark ? const Color(0xFF140f1a) : const Color(0xFF271f30),
                    blurRadius: 4,
                    spreadRadius: 0.5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Refresh button
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          // Refresh IP info
                          ref.read(ipInfoNotifierProvider.notifier).refresh();

                          // Also update the current profile if available
                          final activeProfile = await ref.read(activeProfileProvider.future);
                          if (activeProfile is RemoteProfileEntity) {
                            ref.read(updateProfileProvider(activeProfile.id).notifier).updateProfile(activeProfile);
                          }
                        },
                        customBorder: const CircleBorder(),
                        highlightColor: theme.colorScheme.primary.withOpacity(0.1),
                        splashColor: theme.colorScheme.primary.withOpacity(0.2),
                        child: Ink(
                          width: isDesktop ? 50 : 70,
                          height: isDesktop ? 50 : 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.brightness == Brightness.dark ? const Color(0xFF140f1a) : const Color(0xFF271f30),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            FluentIcons.arrow_sync_20_regular,
                            color: theme.colorScheme.primary,
                            size: isDesktop ? 24 : 30,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Country info
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
                                    info.countryCode,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isDesktop ? 14 : 18,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          AsyncError() => Center(
                              child: Text(
                                t.proxyFooter.check,
                                style: TextStyle(fontSize: isDesktop ? 12 : 14),
                              ),
                            ),
                          _ => Center(
                              child: Text(
                                t.proxyFooter.checking,
                                style: TextStyle(fontSize: isDesktop ? 12 : 14),
                              ),
                            ),
                        },
                      _ => Center(
                          child: Text(
                            t.proxyFooter.notConnected,
                            style: TextStyle(
                              fontSize: isDesktop ? 12 : 14,
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
      ),
    );
  }
}
