import 'package:flutter/material.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/features/profile/add/free_trial_service.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart'; // Add this import
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart'; // Add this for Either extensions

part 'free_trial_initializer.g.dart';

// Create a simpler provider to check for profiles
final hasAnyProfileProvider = FutureProvider<bool>((ref) async {
  final repository = await ref.watch(profileRepositoryProvider.future);
  final hasProfiles = await repository.watchHasAnyProfile().first;
  return hasProfiles.getOrElse((l) => false); // Safely handle the Either type
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
        // Create a free trial profile
        final subscriptionUrl = await ref.read(freeTrialServiceProvider.notifier).claimFreeTrial();

        // Add the profile
        await ref.read(addProfileProvider.notifier).add(subscriptionUrl);

        // Show success message
        ref.read(inAppNotificationControllerProvider).showSuccessToast("Welcome! Your free 1GB trial has been automatically activated.");
      }
    } catch (e) {
      debugPrint("Error claiming free trial: $e");
    }
  }
}
