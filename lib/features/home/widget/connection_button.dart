import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/core/widget/animated_text.dart';
import 'package:hiddify/features/config_option/notifier/config_option_notifier.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ConnectionButton extends HookConsumerWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final isConnected = connectionStatus.valueOrNull is Connected;
    final isReconnectNeeded = ref.watch(configOptionNotifierProvider).valueOrNull == true;
    final isLoading = connectionStatus is AsyncLoading;
    final theme = Theme.of(context);

    // Get theme extension
    final buttonTheme = Theme.of(context).extension<ConnectionButtonTheme>();

    // Use theme colors or fallback to defaults
    final connectedColor = buttonTheme?.connectedColor ?? Colors.green.shade400;
    final idleColor = buttonTheme?.idleColor ?? Colors.red.shade400;

    // Use the appropriate color based on connection state
    final currentColor = isConnected ? connectedColor : idleColor;

    final buttonText = switch (connectionStatus) {
      AsyncData(value: Connected()) when isReconnectNeeded => t.connection.reconnect,
      AsyncData(value: Connected()) => t.connection.connected,
      _ => t.connection.reconnect,
    };

    // Get screen size for responsiveness
    final screenWidth = MediaQuery.of(context).size.width;

    // ===== BUTTON SIZE CUSTOMIZATION =====
    // Modify these values to change button dimensions

    // Button width - increase for wider button
    final toggleWidth = screenWidth < 600 ? screenWidth * 0.45 : 240.0;

    // Button height - modify this multiplier (0.45) to make button taller or shorter
    final toggleHeight = toggleWidth * 0.45;

    // Border width - used for calculations
    const borderWidth = 5.0;

    // Knob size - slightly smaller than the button height to account for border
    final knobSize = toggleHeight - (borderWidth * 4);
    // =====================================

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () async {
            if (!isLoading) {
              await ref.read(connectionNotifierProvider.notifier).toggleConnection();
            }
          },
          child: Container(
            width: toggleWidth,
            height: toggleHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(toggleHeight / 2),
              color: currentColor, // Dynamic color based on connection state
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.brightness == Brightness.dark ? const Color(0xFF140f1a) : const Color(0xFF271f30),
                  offset: const Offset(0, 2),
                  spreadRadius: 1,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Circular knob - horizontal movement
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  // Position the knob at the edge when disconnected, at the right edge when connected
                  // Account for the border width
                  left: isConnected ? toggleWidth - knobSize - (borderWidth * 3) : borderWidth,
                  top: ((toggleHeight - knobSize) / 2) - borderWidth, // Account for the top border
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.white,
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.brightness == Brightness.dark ? const Color(0xFF140f1a) : const Color(0xFF271f30),
                          blurRadius: 4,
                          spreadRadius: 0.5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isLoading
                          ? SizedBox(
                              width: knobSize * 0.5,
                              height: knobSize * 0.5,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(currentColor),
                              ),
                            )
                          : Icon(
                              Icons.settings_power_rounded,
                              color: currentColor,
                              size: knobSize * 0.5,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        AnimatedText(
          buttonText,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: currentColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
        ).animate().fadeIn(duration: 300.ms),
      ],
    );
  }
}
