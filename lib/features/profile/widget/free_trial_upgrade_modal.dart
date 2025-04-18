import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class FreeTrialUpgradeModal extends HookConsumerWidget {
  const FreeTrialUpgradeModal({
    super.key,
    required this.usageRatio,
    this.onDismiss,
  });

  final double usageRatio;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine if the trial is completely used up or almost used up
    final isCompletelyUsed = usageRatio >= 0.99;
    final isAlmostUsed = usageRatio >= 0.90 && usageRatio < 0.99;

    // Website URL to purchase a plan
    const websiteUrl = "https://ipman.uk";

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: isCompletelyUsed ? colorScheme.error.withOpacity(0.1) : colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompletelyUsed ? Icons.warning_rounded : Icons.info_outline_rounded,
                size: 40,
                color: isCompletelyUsed ? colorScheme.error : colorScheme.primary,
              ),
            ),
            const Gap(16),

            // Title
            Text(
              isCompletelyUsed ? "Feee 1 GB VPN ကုန်သွားပါပြီ။" : "Free 1 GB VPN ကုန်ခါနီးပြီနော်!",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(12),

            // Description
            Text(
              isCompletelyUsed
                  ? "သင်ရဲ့ IPမန်း 1 GB Free VPN မှဒေတာ အားလုံးကုန်ဆုံးသွားပါပြီ။ ဆက်လက်သုံးဆွဲနိုင်ရန်အတွက် -ဝယ်မည်- ခလုတ်ကို ကို နှိပ်ပြီး အခုပဲ IPမန်း VPN ပလန်ကိုဝယ်ယူလိုက်ပါ။"
                  : "သင်ရဲ့ IPမန်း 1 GB  Free VPN မှ ဒေတာ ${(usageRatio * 100).toInt()}% ကုန်ဆုံးသွားပါပြီ။ အရှိန်မပျက်ပဲ ဆက်သုံးလိုရအောက် -ဝယ်မည်- ခလုတ်ကို ကို နှိပ်ပြီး အခုပဲ IPမန်း VPN ပလန်ကိုဝယ်ယူလိုက်ပါ။ ",
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Gap(24),

            // Usage indicator
            LinearProgressIndicator(
              value: usageRatio,
              backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF140f1a) : const Color(0xFF271f30).withOpacity(0.2),
              color: isCompletelyUsed
                  ? colorScheme.error
                  : isAlmostUsed
                      ? colorScheme.tertiary
                      : colorScheme.primary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const Gap(8),

            // Usage text
            Text(
              "1GB မှ : ${(usageRatio * 100).toInt()}% သုံးပြီး",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
            const Gap(24),

            // Upgrade button
            ElevatedButton(
              onPressed: () async {
                // Close the dialog
                Navigator.of(context).pop();

                // Launch the website
                final uri = Uri.parse(websiteUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Could not open $websiteUrl")),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                "ဝယ်မည်",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Gap(12),

            // Dismiss button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss?.call();
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "နောက်မှဝယ်မည်",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Provider to track if we've shown the upgrade modal
final hasShownUpgradeModalProvider = StateProvider<bool>((ref) => false);

// Function to show the upgrade modal
Future<void> showFreeTrialUpgradeModal(
  BuildContext context,
  ProviderContainer container,
  double usageRatio,
) async {
  // Check if we've already shown the modal
  final hasShown = container.read(hasShownUpgradeModalProvider);

  // Only show if we haven't shown it before or if it's completely used up
  if (!hasShown || usageRatio >= 0.99) {
    // Mark as shown
    container.read(hasShownUpgradeModalProvider.notifier).state = true;

    // Show the modal
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FreeTrialUpgradeModal(
        usageRatio: usageRatio,
        onDismiss: () {
          // Reset after a day so we can show it again
          Future.delayed(const Duration(days: 1), () {
            container.read(hasShownUpgradeModalProvider.notifier).state = false;
          });
        },
      ),
    );
  }
}

// For testing purposes - a button to show the modal
class ShowUpgradeModalButton extends HookConsumerWidget {
  const ShowUpgradeModalButton({
    super.key,
    this.usageRatio = 1,
  });

  final double usageRatio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () {
        showFreeTrialUpgradeModal(context, ProviderScope.containerOf(context), usageRatio);
      },
      icon: const Icon(Icons.upgrade),
      label: const Text("Test Upgrade Modal"),
    );
  }
}
