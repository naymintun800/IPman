import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/features/common/nested_app_bar.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/home/widget/empty_profiles_home_body.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hiddify/features/proxy/active/active_proxy_footer.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
//import 'package:sliver_tools/sliver_tools.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final hasAnyProfile = ref.watch(hasAnyProfileProvider);
    final activeProfile = ref.watch(activeProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomScrollView(
            slivers: [
              NestedAppBar(
                title: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: t.general.appTitle),
                      const TextSpan(text: " "),
                      const WidgetSpan(
                        child: AppVersionLabel(),
                        alignment: PlaceholderAlignment.middle,
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => const QuickSettingsRoute().push(context),
                    icon: const Icon(FluentIcons.options_24_filled),
                    tooltip: t.config.quickSettings,
                  ),
                  IconButton(
                    onPressed: () => const AddProfileRoute().push(context),
                    icon: const Icon(FluentIcons.add_circle_24_filled),
                    tooltip: t.profile.add.buttonText,
                  ),
                ],
              ),
              switch (activeProfile) {
                AsyncData(value: final profile?) => SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),

                          // Logo area (clickable for remote profiles)
                          GestureDetector(
                            onTap: () {
                              if (profile is RemoteProfileEntity) {
                                ref.read(updateProfileProvider(profile.id).notifier).updateProfile(profile as RemoteProfileEntity);
                              }
                            },
                            child: Container(
                              width: 160,
                              height: 160,
                              child: Center(
                                // child: Text(
                                //   "IP",
                                //   style: TextStyle(
                                //     fontSize: 60,
                                //     fontWeight: FontWeight.bold,
                                //     color: theme.colorScheme.primary,
                                //   ),
                                // ),
                                // Uncomment when logo is ready
                                child: SvgPicture.asset(
                                  'assets/images/ipmanLogo.svg',
                                ),
                              ),
                            ),
                          ),

                          // Profile name - direct text as in reference
                          Text(
                            profile.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 10),

                          // Usage info with null safety - directly on page
                          if (profile is RemoteProfileEntity) ...[
                            Builder(
                              builder: (context) {
                                final subInfo = (profile as RemoteProfileEntity).subInfo;
                                if (subInfo == null) {
                                  return const SizedBox.shrink();
                                }

                                String usageText = "No data";

                                // Check if it's unlimited
                                if (subInfo.total > 10 * 1099511627776) {
                                  // 10TB
                                  usageText = "Unlimited";
                                } else {
                                  final consumption = subInfo.consumption?.sizeGB() ?? '0';
                                  final total = subInfo.total?.sizeGB() ?? '∞';
                                  usageText = "$consumption/$total";
                                }

                                return Text(
                                  usageText,
                                  style: theme.textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                );
                              },
                            ),

                            const SizedBox(height: 3),

                            // Improved progress bar to match reference
                            // Progress bar section
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Builder(
                                builder: (context) {
                                  final subInfo = (profile as RemoteProfileEntity).subInfo;
                                  final ratio = subInfo?.ratio ?? 0.0;

                                  // Add padding around the outer container
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                    child: Container(
                                      height: 54,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        // Use a distinct color for the outer container
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.brightness == Brightness.dark ? const Color(0xFF140f1a) : const Color(0xFF271f30),
                                            offset: const Offset(0, 3),
                                            spreadRadius: 4,
                                          ),
                                        ],
                                      ),
                                      // Add padding inside the outer container
                                      padding: const EdgeInsets.all(8),
                                      child: Container(
                                        // Inner container that holds the progress
                                        decoration: BoxDecoration(
                                          color: theme.brightness == Brightness.dark ? const Color(0xFF140f1a) : const Color(0xFF271f30),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Stack(
                                          children: [
                                            // Background - full width
                                            Container(
                                              decoration: BoxDecoration(
                                                color: theme.brightness == Brightness.dark ? const Color(0xFF140f1a) : const Color(0xFF271f30),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            // Foreground - progress portion
                                            FractionallySizedBox(
                                              widthFactor: ratio < 1.0 ? ratio : 1.0,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primary,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],

                          const SizedBox(height: 15),

                          // Connection button
                          const ConnectionButton(),

                          const SizedBox(height: 5),
                          const ActiveProxyDelayIndicator(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                AsyncData() => switch (hasAnyProfile) {
                    AsyncData(value: true) => const EmptyActiveProfileHomeBody(),
                    _ => const EmptyProfilesHomeBody(),
                  },
                AsyncError(:final error) => SliverErrorBodyPlaceholder(t.presentShortError(error)),
                _ => const SliverToBoxAdapter(),
              },
            ],
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ActiveProxyFooter(),
          ),
        ],
      ),
    );
  }
}

class AppVersionLabel extends HookConsumerWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    final version = ref.watch(appInfoProvider).requireValue.presentVersion;
    if (version.isBlank) return const SizedBox();

    return Semantics(
      label: t.about.version,
      button: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 1,
        ),
        child: Text(
          version,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
