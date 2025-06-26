import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/profile/add/free_trial_service.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/utils/alerts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EmptyProfilesHomeBody extends HookConsumerWidget {
  const EmptyProfilesHomeBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final isClaimingFreeTrial = useState(false);
    final isForcingFreeTrial = useState(false);

    Future<void> forceClaimFreeTrial() async {
      if (isForcingFreeTrial.value) return;

      try {
        isForcingFreeTrial.value = true;
        if (context.mounted) {
          const CustomToast("Forcing new free trial...").show(context);
        }

        final subscriptionUrl = await ref.read(freeTrialServiceProvider.notifier).forceClaimFreeTrialForDebug();

        await ref.read(addProfileProvider.notifier).add(subscriptionUrl);

        if (context.mounted) {
          const CustomToast.success("Debug free trial added!").show(context);
        }
      } catch (e) {
        if (context.mounted) {
          CustomToast.error(e.toString()).show(context);
        }
      } finally {
        isForcingFreeTrial.value = false;
      }
    }

    Future<void> claimFreeTrial() async {
      if (isClaimingFreeTrial.value) return;

      try {
        isClaimingFreeTrial.value = true;

        // Check if free trial has been claimed before
        final hasClaimed = await ref.read(freeTrialServiceProvider.future);

        if (hasClaimed) {
          // If already claimed, try to get the stored URL
          final storedUrl = await ref.read(freeTrialServiceProvider.notifier).getStoredSubscriptionUrl();

          if (storedUrl != null && storedUrl.isNotEmpty) {
            // Add the profile using the stored URL
            await ref.read(addProfileProvider.notifier).add(storedUrl);
            if (context.mounted) {
              const CustomToast.success("သင့် Free 1GB အားပြန်လည်ထည့်သွင်းပြီးပါပြီ").show(context);
            }
            return;
          }
        }

        // Show a message that we're setting up the free trial
        if (context.mounted) {
          const CustomToast.success("Free 1GB ရယူနေသည်...").show(context);
        }

        // Create a free trial profile
        final subscriptionUrl = await ref.read(freeTrialServiceProvider.notifier).claimFreeTrial();

        // Add the profile
        await ref.read(addProfileProvider.notifier).add(subscriptionUrl);

        // Show success message
        if (context.mounted) {
          const CustomToast.success("Free 1GB ရယူပြီးပါပြီ!").show(context);
        }
      } catch (e) {
        // Handle specific error messages from the free trial service
        if (context.mounted) {
          if (e is FreeTrialFailure) {
            CustomToast.error(e.toString()).show(context);
          } else {
            const CustomToast.error("Free 1GB ရယူရန် Error တက်နေသည်။ နောက်မှကြိုးစားပါ။").show(context);
          }
        }
        debugPrint("Free 1GB ရယူရန် Error တက်နေသည်- $e");
      } finally {
        isClaimingFreeTrial.value = false;
      }
    }

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(t.home.emptyProfilesMsg),
          const Gap(24),
          // Debug Button
          if (kDebugMode) ...[
            ElevatedButton.icon(
              onPressed: isForcingFreeTrial.value ? null : forceClaimFreeTrial,
              icon: isForcingFreeTrial.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bug_report),
              label: const Text("Force New 1GB (Debug)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const Gap(16),
          ],
          // Free 1GB Trial Button
          ElevatedButton.icon(
            onPressed: isClaimingFreeTrial.value ? null : claimFreeTrial,
            icon: isClaimingFreeTrial.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(FluentIcons.gift_24_regular),
            label: const Text("Free 1GB ရယူရန်"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const Gap(16),
          // Regular Add Profile Button
          OutlinedButton.icon(
            onPressed: () => const AddProfileRoute().push(context),
            icon: const Icon(FluentIcons.add_24_regular),
            label: Text(t.profile.add.buttonText),
          ),

          // TESTING ONLY - Remove this section before production
/*           const Gap(32),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                const Text(
                  "DEBUG - FOR TESTING ONLY",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                const Gap(8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(freeTrialServiceProvider.notifier).resetEverythingForTesting();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Free trial reset complete. Restart app to test again.",
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Reset Free Trial"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[100],
                    foregroundColor: Colors.red[900],
                  ),
                ),
              ],
            ),
          ), */
          // END TESTING SECTION
        ],
      ),
    );
  }
}

class EmptyActiveProfileHomeBody extends HookConsumerWidget {
  const EmptyActiveProfileHomeBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(t.home.noActiveProfileMsg),
          const Gap(16),
          OutlinedButton(
            onPressed: () => const ProfilesOverviewRoute().push(context),
            child: Text(t.profile.overviewPageTitle),
          ),
        ],
      ),
    );
  }
}
