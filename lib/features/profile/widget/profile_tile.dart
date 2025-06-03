import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/core/widget/adaptive_icon.dart';
import 'package:hiddify/core/widget/adaptive_menu.dart';
import 'package:hiddify/features/common/confirmation_dialogs.dart';
import 'package:hiddify/features/common/qr_code_dialog.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/profile/overview/profiles_overview_notifier.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ProfileTile extends HookConsumerWidget {
  const ProfileTile({
    super.key,
    required this.profile,
    this.isMain = false,
  });

  final ProfileEntity profile;

  /// home screen active profile card
  final bool isMain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    final selectActiveMutation = useMutation(
      initialOnFailure: (err) {
        CustomToast.error(t.presentShortError(err)).show(context);
      },
      initialOnSuccess: () {
        if (context.mounted && context.canPop()) context.pop();
      },
    );

    final subInfo = switch (profile) {
      RemoteProfileEntity(:final subInfo) => subInfo,
      _ => null,
    };

    // Skip customization for main profile as it's already handled in home page
    if (isMain) {
      const effectiveMargin = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      final effectiveOutlineColor = theme.colorScheme.outlineVariant;

      // Enhanced main profile card with custom shadow
      return Container(
        margin: effectiveMargin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.dark ? const Color(0xFF140f1a) : const Color(0xFF271f30),
              offset: const Offset(0, 3),
              spreadRadius: 2,
              blurRadius: 2,
            ),
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: effectiveOutlineColor),
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (profile is RemoteProfileEntity) ...[
                  SizedBox(
                    width: 48,
                    child: Semantics(
                      sortKey: const OrdinalSortKey(1),
                      child: ProfileActionButton(profile, false),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    color: effectiveOutlineColor,
                  ),
                ],
                Expanded(
                  child: Semantics(
                    button: true,
                    sortKey: const OrdinalSortKey(0),
                    focused: true,
                    liveRegion: true,
                    namesRoute: true,
                    label: t.profile.activeProfileBtnSemanticLabel,
                    child: InkWell(
                      onTap: () => const ProfilesOverviewRoute().go(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Material(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.transparent,
                                clipBehavior: Clip.antiAlias,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        profile.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontFamily: FontFamily.emoji,
                                        ),
                                        semanticsLabel: t.profile.activeProfileNameSemanticLabel(
                                          name: profile.name,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      FluentIcons.caret_down_16_filled,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (subInfo != null) ...[
                              const Gap(6),
                              RemainingTrafficIndicator(subInfo.ratio),
                              const Gap(6),
                              // Enhanced data usage display for main profile
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ProfileSubscriptionInfo(subInfo),
                              ),
                              const Gap(6),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Custom minimal design for non-main profiles
    final isActive = profile.active;
    final cardColor = isActive ? theme.colorScheme.primaryContainer.withOpacity(0.7) : theme.colorScheme.surface;
    final textColor = isActive ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface;

    // Use Container with BoxShadow instead of Card for better shadow control
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark ? const Color(0xFF140f1a) : const Color(0xFF271f30),
            offset: const Offset(0, 3),
            spreadRadius: 2,
            blurRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (selectActiveMutation.state.isInProgress) return;
          if (isActive) return;
          selectActiveMutation.setFuture(
            ref.read(profilesOverviewNotifierProvider.notifier).selectActiveProfile(profile.id),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              // Action button on the left
              if (profile is RemoteProfileEntity) ...[
                Container(
                  width: 40,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isActive ? theme.colorScheme.primary.withOpacity(0.3) : theme.colorScheme.primary.withOpacity(0.2),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: ProfileActionButton(profile, true),
                ),
                const SizedBox(width: 8),
              ],
              // Profile content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile name
                      Text(
                        profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: textColor,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      // Traffic indicator if available
                      if (subInfo != null) ...[
                        const SizedBox(height: 6),
                        RemainingTrafficIndicator(subInfo.ratio),
                        const SizedBox(height: 4),
                        // Only show data usage, not days remaining
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive ? theme.colorScheme.primaryContainer.withOpacity(0.4) : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              subInfo.total > 10 * 1099511627776 //10TB
                                  ? "∞ GiB"
                                  : subInfo.consumption.sizeOf(subInfo.total),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Active indicator
              if (isActive)
                Container(
                  width: 4,
                  height: 50,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileActionButton extends HookConsumerWidget {
  const ProfileActionButton(this.profile, this.showAllActions, {super.key});

  final ProfileEntity profile;
  final bool showAllActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    if (profile case RemoteProfileEntity() when !showAllActions) {
      return Semantics(
        button: true,
        enabled: !ref.watch(updateProfileProvider(profile.id)).isLoading,
        child: Tooltip(
          message: t.profile.update.tooltip,
          child: InkWell(
            onTap: () {
              if (ref.read(updateProfileProvider(profile.id)).isLoading) {
                return;
              }
              ref.read(updateProfileProvider(profile.id).notifier).updateProfile(profile as RemoteProfileEntity);
            },
            child: const Icon(FluentIcons.arrow_sync_24_filled),
          ),
        ),
      );
    }
    return ProfileActionsMenu(
      profile,
      (context, toggleVisibility, _) {
        return Semantics(
          button: true,
          child: Tooltip(
            message: MaterialLocalizations.of(context).showMenuTooltip,
            child: InkWell(
              onTap: toggleVisibility,
              child: Icon(AdaptiveIcon(context).more),
            ),
          ),
        );
      },
    );
  }
}

class ProfileActionsMenu extends HookConsumerWidget {
  const ProfileActionsMenu(this.profile, this.builder, {super.key, this.child});

  final ProfileEntity profile;
  final AdaptiveMenuBuilder builder;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    final exportConfigMutation = useMutation(
      initialOnFailure: (err) {
        CustomToast.error(t.presentShortError(err)).show(context);
      },
      initialOnSuccess: () => CustomToast.success(t.profile.share.exportConfigToClipboardSuccess).show(context),
    );
    final deleteProfileMutation = useMutation(
      initialOnFailure: (err) {
        CustomAlertDialog.fromErr(t.presentError(err)).show(context);
      },
    );

    bool shouldShowShareButton = false;
    if (profile case RemoteProfileEntity(:final url)) {
      try {
        final uri = Uri.parse(url);
        final host = uri.host;
        final domainParts = host.split('.');
        if (domainParts.isNotEmpty) {
          final subdomain = domainParts.first;
          if (subdomain == 'profile' || subdomain.startsWith('server')) {
            shouldShowShareButton = true;
          }
        }
      } catch (e) {
        // If parsing fails, treat as not sharable
        shouldShowShareButton = false;
      }
    }

    final menuItems = [
      if (profile case RemoteProfileEntity())
        AdaptiveMenuItem(
          title: t.profile.update.buttonTxt,
          icon: FluentIcons.arrow_sync_24_regular,
          onTap: () {
            if (ref.read(updateProfileProvider(profile.id)).isLoading) {
              return;
            }
            ref.read(updateProfileProvider(profile.id).notifier).updateProfile(profile as RemoteProfileEntity);
          },
        ),
      if (shouldShowShareButton)
        AdaptiveMenuItem(
          title: t.profile.share.buttonText,
          icon: AdaptiveIcon(context).share,
          subItems: [
            if (profile case RemoteProfileEntity(:final url, :final name)) ...[
              AdaptiveMenuItem(
                title: t.profile.share.exportSubLinkToClipboard,
                onTap: () async {
                  final link = LinkParser.generateSubShareLink(url, name);
                  if (link.isNotEmpty) {
                    await Clipboard.setData(ClipboardData(text: link));
                    if (context.mounted) {
                      CustomToast(t.profile.share.exportToClipboardSuccess).show(context);
                    }
                  }
                },
              ),
              AdaptiveMenuItem(
                title: t.profile.share.subLinkQrCode,
                onTap: () async {
                  final link = LinkParser.generateSubShareLink(url, name);
                  if (link.isNotEmpty) {
                    await QrCodeDialog(
                      link,
                      message: name,
                    ).show(context);
                  }
                },
              ),
            ],
            AdaptiveMenuItem(
              title: t.profile.share.exportConfigToClipboard,
              onTap: () async {
                if (exportConfigMutation.state.isInProgress) {
                  return;
                }
                exportConfigMutation.setFuture(
                  ref.read(profilesOverviewNotifierProvider.notifier).exportConfigToClipboard(profile),
                );
              },
            ),
          ],
        ),
      // Edit button removed as requested
      AdaptiveMenuItem(
        icon: FluentIcons.delete_24_regular,
        title: t.profile.delete.buttonTxt,
        onTap: () async {
          if (deleteProfileMutation.state.isInProgress) {
            return;
          }
          final deleteConfirmed = await showConfirmationDialog(
            context,
            title: t.profile.delete.buttonTxt,
            message: t.profile.delete.confirmationMsg,
            icon: FluentIcons.delete_24_regular,
          );
          if (deleteConfirmed) {
            deleteProfileMutation.setFuture(
              ref.read(profilesOverviewNotifierProvider.notifier).deleteProfile(profile),
            );
          }
        },
      ),
    ];

    return AdaptiveMenu(
      builder: builder,
      items: menuItems,
      child: child,
    );
  }
}

// Modified to remove days remaining display
class ProfileSubscriptionInfo extends HookConsumerWidget {
  const ProfileSubscriptionInfo(this.subInfo, {super.key});

  final SubscriptionInfo subInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    // Only show data usage information
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        subInfo.total > 10 * 1099511627776 //10TB
            ? "∞ GiB"
            : subInfo.consumption.sizeOf(subInfo.total),
        semanticsLabel: t.profile.subscription.remainingTrafficSemanticLabel(
          consumed: subInfo.consumption.sizeGB(),
          total: subInfo.total.sizeGB(),
        ),
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class RemainingTrafficIndicator extends StatelessWidget {
  const RemainingTrafficIndicator(this.ratio, {super.key});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use theme colors for a more consistent look
    final startColor = ratio < 0.25
        ? theme.colorScheme.primary
        : ratio < 0.65
            ? theme.colorScheme.tertiary
            : theme.colorScheme.error;
    final endColor = ratio < 0.25
        ? theme.colorScheme.primary.withOpacity(0.8)
        : ratio < 0.65
            ? theme.colorScheme.tertiary.withOpacity(0.8)
            : theme.colorScheme.error.withOpacity(0.8);

    // Container with custom styling for better appearance
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: LinearPercentIndicator(
        percent: ratio,
        animation: true,
        padding: EdgeInsets.zero,
        lineHeight: 24, // Increased height as requested
        barRadius: const Radius.circular(10),
        backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF140f1a) : const Color(0xFF271f30),
        linearGradient: LinearGradient(
          colors: [startColor, endColor],
          stops: const [0.3, 1.0],
        ),
      ),
    );
  }
}
