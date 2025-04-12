import 'package:flutter/material.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/widgets/currency_bar.dart';
import 'package:idlefit/widgets/current_coins.dart';
import 'dart:math';

class AnimationUtils {
  static OverlayEntry? _overlayEntry;
  static AnimationController? _animationController;

  static void startFlyingCurrencyAnimation({
    required BuildContext context,
    required TickerProvider vsync,
    required Offset startPosition,
    required CurrencyType currencyType,
    int numberOfIcons = 8,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    // Find the target GlobalKey based on currency type
    GlobalKey? targetKey;
    switch (currencyType) {
      case CurrencyType.coin:
        targetKey = CurrentCoins.globalKey;
        break;
      case CurrencyType.energy:
        targetKey = CurrencyWidget.energyGlobalKey;
        break;
      case CurrencyType.space:
        targetKey = CurrencyWidget.spaceGlobalKey;
        break;
      default:
        print("Error: Unsupported currency type for animation $currencyType");
        return; // Don't animate if target is unknown
    }

    final RenderBox? targetBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (!context.mounted || targetBox == null) return;

    final targetPosition = targetBox.localToGlobal(
      targetBox.size.center(Offset.zero),
    );

    // Dispose previous controller and remove overlay if any
    _animationController?.dispose();
    _overlayEntry?.remove();
    _overlayEntry = null;

    _animationController = AnimationController(
      vsync: vsync,
      duration: duration,
    );

    final random = Random();
    final List<Animation<Offset>> iconAnimations = [];
    final List<Animation<double>> iconOpacityAnimations = [];
    final double animDurationMs = duration.inMilliseconds.toDouble();

    for (int i = 0; i < numberOfIcons; i++) {
      // Add slight random offset to start position for spread
      final startOffset = Offset(
        startPosition.dx + random.nextDouble() * 40 - 20, // Spread horizontally
        startPosition.dy + random.nextDouble() * 30 - 15, // Spread vertically
      );

      // Add slight random offset to target position
      final endOffset = Offset(
        targetPosition.dx + random.nextDouble() * 20 - 10,
        targetPosition.dy + random.nextDouble() * 10 - 5,
      );

      // Stagger animation start times slightly
      final startDelay = i * (animDurationMs * 0.3 / numberOfIcons);
      final intervalStart = (startDelay / animDurationMs).clamp(0.0, 1.0);
      final intervalEnd = (intervalStart + 0.7).clamp(
        intervalStart,
        1.0,
      ); // Ensure end >= start
      final fadeStart = (intervalStart + (intervalEnd - intervalStart) * 0.7)
          .clamp(0.0, 1.0);

      final curve = CurvedAnimation(
        parent: _animationController!,
        curve: Interval(
          intervalStart,
          intervalEnd,
          curve: Curves.easeOutQuad, // Use a curve for smoother movement
        ),
      );

      iconAnimations.add(
        Tween<Offset>(begin: startOffset, end: endOffset).animate(curve),
      );

      // Fade out animation towards the end
      iconOpacityAnimations.add(
        Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _animationController!,
            curve: Interval(
              fadeStart,
              1.0,
              curve: Curves.easeIn, // Start fading in the last part
            ),
          ),
        ),
      );
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: _animationController!,
          builder: (context, child) {
            // Check if controller is disposed before accessing value
            if (!_animationController!.isAnimating &&
                _animationController!.value == 0.0 &&
                iconAnimations.isEmpty) {
              return const SizedBox.shrink();
            }

            return Stack(
              children: List.generate(numberOfIcons, (index) {
                // Additional safety checks
                if (index >= iconAnimations.length ||
                    index >= iconOpacityAnimations.length) {
                  return const SizedBox.shrink();
                }
                final position = iconAnimations[index].value;
                final opacity = iconOpacityAnimations[index].value;

                // Prevent rendering if opacity is zero
                if (opacity <= 0) return const SizedBox.shrink();

                return Positioned(
                  left: position.dx - 8, // Adjust for icon size centering
                  top: position.dy - 8,
                  child: Opacity(
                    // Using Opacity widget
                    opacity: opacity,
                    child: currencyType.iconWithSize(
                      16,
                    ), // Use correct currency icon
                  ),
                );
              }),
            );
          },
        );
      },
    );

    // Add status listener AFTER creating the OverlayEntry
    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        // Don't reset controller here, let dispose handle it
      }
    });

    Overlay.of(context).insert(_overlayEntry!);
    _animationController!.forward(from: 0.0);
  }

  // Optional: Method to clean up if needed externally, though dispose should handle it
  static void disposeController() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _animationController?.dispose();
    _animationController = null;
  }
}
