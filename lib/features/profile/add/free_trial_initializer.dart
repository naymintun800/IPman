import 'package:flutter/material.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/features/profile/add/free_trial_service.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'free_trial_initializer.g.dart';

// Create a simpler provider to check for profiles
final hasAnyProfileProvider = FutureProvider<bool>((ref) async {
  final repository = await ref.watch(profileRepositoryProvider.future);
  final hasProfiles = await repository.watchHasAnyProfile().first;
  return hasProfiles.fold((l) => false, (r) => r); // Safely handle the Either type
});

@riverpod
class FreeTrialInitializer extends _$FreeTrialInitializer {
  @override
  Future<void> build() async {
    // Initialize and trigger free trial check after a short delay
    Future.delayed(const Duration(seconds: 3), () => _checkAndClaimFreeTrial());
    return;
  }

  Future<void> _checkAndClaimFreeTrial() async {
    try {
      // Check if any profiles exist
      final hasAnyProfile = await ref.read(hasAnyProfileProvider.future);

      // Check if free trial has been claimed before
      final hasClaimed = await ref.read(freeTrialServiceProvider.future);

      // Only claim if no profiles exist and hasn't claimed free trial before
      if (hasAnyProfile == false && hasClaimed == false) {
        // Show a message that we're setting up the free trial
        ref.read(inAppNotificationControllerProvider).showInfoToast("Setting up your free 1GB trial...");

        try {
          // Create a free trial profile
          final subscriptionUrl = await ref.read(freeTrialServiceProvider.notifier).claimFreeTrial();

          // Add the profile
          await ref.read(addProfileProvider.notifier).add(subscriptionUrl);

          // Show success message
          ref.read(inAppNotificationControllerProvider).showSuccessToast("Welcome! Your free 1GB trial has been automatically activated.");
        } catch (e) {
          // Handle specific error messages from the free trial service
          if (e is FreeTrialFailure) {
            ref.read(inAppNotificationControllerProvider).showErrorToast(e.toString());
          } else {
            ref.read(inAppNotificationControllerProvider).showErrorToast("Could not activate free trial. Please try again later.");
          }
          debugPrint("Error claiming free trial: $e");
        }
      }
    } catch (e) {
      debugPrint("Error in free trial initialization: $e");
    }
  }
}
