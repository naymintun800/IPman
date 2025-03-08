import 'package:flutter/material.dart';

class BottomSheetPage extends Page {
  const BottomSheetPage({
    super.key,
    super.name,
    required this.builder,
    this.fixed = false,
    this.backgroundColor,
    this.barrierColor,
  });

  final Widget Function(ScrollController? controller) builder;
  final bool fixed;
  final Color? backgroundColor;
  final Color? barrierColor;

  @override
  Route<void> createRoute(BuildContext context) {
    // Get the current theme
    final theme = Theme.of(context);

    return ModalBottomSheetRoute(
      settings: this,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      // Use theme surface color for the modal by default
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      // Use semi-transparent surface color for the barrier by default
      //modalBarrierColor: barrierColor ?? theme.colorScheme.surface.withOpacity(0.7),
      builder: (_) {
        if (!fixed) {
          return DraggableScrollableSheet(
            expand: false,
            builder: (_, scrollController) => builder(scrollController),
          );
        }
        return builder(null);
      },
    );
  }
}
