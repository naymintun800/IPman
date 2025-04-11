import 'package:flutter/material.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/profile/add/free_trial_service.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/widget/free_trial_upgrade_modal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'free_trial_usage_checker.g.dart';

@riverpod
class FreeTrialUsageChecker extends _$FreeTrialUsageChecker {
  @override
  Future<void> build() async {
    // Initialize and check free trial usage after a short delay
    Future.delayed(const Duration(seconds: 5), () => _checkFreeTrialUsage());
    return;
  }

  Future<void> _checkFreeTrialUsage() async {
    try {
      // Get the free trial service
      final freeTrialService = await ref.read(freeTrialServiceProvider.future);

      // If free trial hasn't been claimed, no need to check usage
      if (!freeTrialService) return;

      // Get the subscription URL
      final subscriptionUrl = await ref.read(freeTrialServiceProvider.notifier).getStoredSubscriptionUrl();
      if (subscriptionUrl == null) return;

      // Get all profiles
      final repository = await ref.read(profileRepositoryProvider.future);
      final profilesStream = repository.watchAll();
      final profilesResult = await profilesStream.first;

      // Find the free trial profile
      final profiles = profilesResult.fold((l) => <ProfileEntity>[], (r) => r);
      RemoteProfileEntity? freeTrialProfile;
      try {
        freeTrialProfile = profiles.firstWhere(
          (profile) => profile is RemoteProfileEntity && profile.url == subscriptionUrl,
        ) as RemoteProfileEntity;
      } catch (_) {
        // Profile not found
        return;
      }

      // Check if it has subscription info
      if (freeTrialProfile.subInfo != null) {
        final subInfo = freeTrialProfile.subInfo!;
        final usageRatio = subInfo.ratio;

        // If usage is high (>90%), show the upgrade modal
        if (usageRatio >= 0.90) {
          // Get the router
          final router = ref.read(routerProvider);
          final context = router.routerDelegate.navigatorKey.currentContext;
          if (context != null && context.mounted) {
            // Show the upgrade modal using a BuildContext that won't be used across async gaps
            final currentContext = context;
            await Future.microtask(() {
              if (currentContext.mounted) {
                showFreeTrialUpgradeModal(currentContext, ProviderScope.containerOf(currentContext), usageRatio);
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking free trial usage: $e");
    }
  }

  // Method to manually check usage (for testing)
  Future<void> checkUsageNow() async {
    await _checkFreeTrialUsage();
  }
}
