import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/common/general_pref_tiles.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

class IntroPage extends HookConsumerWidget with PresLogger {
  IntroPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final isStarting = useState(false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Set region to 'other' by default
    // This replaces the auto region selection
    _setDefaultRegion(ref);

    // Set Myanmar language as default
    _setDefaultLanguage(ref);

    return Scaffold(
      body: Container(
        // Clean, modern background using app's color scheme
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.dark
                ? [
                    colorScheme.surface,
                    colorScheme.surface.withOpacity(0.7),
                  ]
                : [
                    colorScheme.primary.withOpacity(0.05),
                    colorScheme.surface,
                  ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            shrinkWrap: true,
            slivers: [
              // App logo - clean and modern
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      // Logo without container
                      SizedBox(
                        width: 140, // Smaller logo size
                        height: 140,
                        child: Hero(
                          tag: 'app_logo',
                          child: Assets.images.ipmanLogo.svg(),
                        ),
                      ),

                      // App name with stylish text
                    ],
                  ),
                ),
              ),

              // Tagline

              SliverCrossAxisConstrained(
                maxCrossAxisExtent: 368,
                child: MultiSliver(
                  children: [
                    const Gap(24),

                    // Language selection - sleek design
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark ? colorScheme.surface.withOpacity(0.3) : colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: LocalePrefTile(),
                      ),
                    ),

                    const Gap(16),

                    // Analytics option - matching design
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark ? colorScheme.surface.withOpacity(0.3) : colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: EnableAnalyticsPrefTile(),
                      ),
                    ),

                    const Gap(24),

                    // Terms and conditions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text.rich(
                        t.intro.termsAndPolicyCaution(
                          tap: (text) => TextSpan(
                            text: text,
                            style: TextStyle(color: colorScheme.primary),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                await UriUtils.tryLaunch(
                                  Uri.parse(Constants.termsAndConditionsUrl),
                                );
                              },
                          ),
                        ),
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Get Started button - modern and sleek
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withOpacity(0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              if (isStarting.value) return;
                              isStarting.value = true;
                              if (!ref.read(analyticsControllerProvider).requireValue) {
                                loggy.info("disabling analytics per user request");
                                try {
                                  await ref.read(analyticsControllerProvider.notifier).disableAnalytics();
                                } catch (error, stackTrace) {
                                  loggy.error(
                                    "could not disable analytics",
                                    error,
                                    stackTrace,
                                  );
                                }
                              }
                              await ref.read(Preferences.introCompleted.notifier).update(true);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: isStarting.value
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: colorScheme.onPrimary,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          t.intro.start,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                            color: colorScheme.onPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: colorScheme.onPrimary,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Simple method to set region to 'other' by default
  void _setDefaultRegion(WidgetRef ref) {
    // Set region to 'other'
    ref.read(ConfigOptions.region.notifier).update(Region.other);

    // Reset DNS address to ensure it's properly configured
    ref.read(ConfigOptions.directDnsAddress.notifier).reset();
  }

  // Method to set Myanmar language as default
  void _setDefaultLanguage(WidgetRef ref) {
    // Set language to Myanmar (my)
    ref.read(localePreferencesProvider.notifier).changeLocale(AppLocale.my);
  }
}

// Removed RegionLocale class as it's no longer needed
