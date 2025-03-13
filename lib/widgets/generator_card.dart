import 'package:flutter/material.dart';
import 'package:idlefit/constants.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/util.dart';
import 'package:idlefit/widgets/current_coins.dart';
import 'common_card.dart';

class GeneratorCard extends StatefulWidget {
  final CoinGenerator generator;
  final VoidCallback onBuy;
  final VoidCallback? onUpgrade;
  final VoidCallback? onUnlock;

  const GeneratorCard({
    super.key,
    required this.generator,
    required this.onBuy,
    this.onUpgrade,
    this.onUnlock,
  });

  @override
  _GeneratorCardState createState() => _GeneratorCardState();
}

class _GeneratorCardState extends State<GeneratorCard>
    with SingleTickerProviderStateMixin {
  double progress = 0.0;
  bool showProgress = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;
  final duration = 500;
  Offset? _tapLocation;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 1.2, end: 0.8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.5),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        _animationController.reset();
      }
    });
  }

  void startProgress(TapDownDetails details) {
    if (showProgress || widget.generator.count < 1) {
      return;
    }

    // Store tap location
    _tapLocation = details.localPosition;

    setState(() {
      progress = 0.0; // Reset progress
      showProgress = true; // Show progress bar
    });
    Future.delayed(Duration(milliseconds: 50), () {
      // Ensure animation starts
      setState(() => progress = 1.0);
    });

    Future.delayed(Duration(milliseconds: duration), () {
      if (!mounted) return;
      setState(() {
        showProgress = false;
      }); // Hide bar after animation completes

      final output =
          widget.generator.tier == 1 ? 15.0 : widget.generator.singleOutput;
      _showFloatingText(toLettersNotation(output));
      CurrentCoins.triggerAnimation();
      // Trigger the animation
    });
  }

  void _showFloatingText(String text) {
    if (!mounted || _tapLocation == null || !context.mounted) return;

    final RenderBox? cardRenderBox = context.findRenderObject() as RenderBox?;
    if (cardRenderBox == null) return;

    // Get global positions
    final cardPosition = cardRenderBox.localToGlobal(Offset.zero);

    // Calculate start position
    final startX = cardPosition.dx + _tapLocation!.dx;
    final startY = cardPosition.dy + _tapLocation!.dy;

    // Remove existing overlay if any
    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Positioned(
              left: startX - 40, // Center the text around tap point
              top: startY,
              child: SlideTransition(
                position: _positionAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber, width: 1),
                      ),
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: Text('+$text'),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // Insert the overlay entry
    if (context.mounted) {
      Overlay.of(context).insert(_overlayEntry!);
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generator = widget.generator;
    final screenWidth = MediaQuery.of(context).size.width;
    final additionalInfo = [
      Row(
        children: [
          Text(
            'Produces: ${toLettersNotation(generator.singleOutput)} ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Icon(Constants.coinIcon, color: Colors.amber, size: 16),
          Text('/s', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ];
    if (generator.count > 0) {
      additionalInfo.add(
        Row(
          children: [
            Text(
              'Output: ${toLettersNotation(generator.output)} ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Icon(Constants.coinIcon, color: Colors.amber, size: 16),
            Text('/s', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    // Show upgrades if generator is unlocked
    if (generator.isUnlocked) {
      additionalInfo.add(
        Row(
          children: [
            Text(
              'Level: ${generator.level}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 4),
            Icon(Icons.upgrade, color: Colors.blue, size: 16),
          ],
        ),
      );
    } else if (generator.count >= 10) {
      additionalInfo.add(
        Row(
          children: [
            Text(
              'Unlock upgrades!',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.amber),
            ),
            const SizedBox(width: 4),
            Icon(Icons.lock_open, color: Colors.amber, size: 16),
          ],
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none, // Allow animations to move outside bounds
      children: [
        CommonCard(
          title: generator.name,
          rightText: 'Reps: ${generator.count}',
          description: generator.description,
          additionalInfo: additionalInfo,
          cost: generator.cost,
          affordable: true, // This will be handled by the game engine
          costIcon: Constants.coinIcon,
          buttonText: 'Add Rep',
          onButtonPressed: widget.onBuy,
          onTapDown: showProgress || generator.count < 1 ? null : startProgress,
          progressIndicator:
              showProgress
                  ? AnimatedContainer(
                    duration: Duration(milliseconds: duration),
                    height: 5,
                    width: progress * (screenWidth - 32),
                    color: Colors.blue,
                  )
                  : null,
          secondaryButtonText:
              generator.isUnlocked
                  ? 'Upgrade'
                  : (generator.count >= 10 ? 'Unlock' : null),
          onSecondaryButtonPressed:
              generator.isUnlocked
                  ? widget.onUpgrade
                  : (generator.count >= 10 ? widget.onUnlock : null),
        ),
      ],
    );
  }
}
