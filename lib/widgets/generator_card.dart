import 'package:flutter/material.dart';
import 'package:idlefit/services/game_state.dart';
import 'package:idlefit/util.dart';

class GeneratorCard extends StatefulWidget {
  final GameState gameState;
  final int generatorIndex;
  const GeneratorCard({
    super.key,
    required this.gameState,
    required this.generatorIndex,
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
    if (showProgress ||
        widget.gameState.coinGenerators[widget.generatorIndex].count < 1) {
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

      final generator = widget.gameState.coinGenerators[widget.generatorIndex];
      widget.gameState.coins.earn(generator.tapOutput);
      _showFloatingText(toLettersNotation(generator.tapOutput));
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
    final generator = widget.gameState.coinGenerators[widget.generatorIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      clipBehavior: Clip.none, // Allow animations to move outside bounds
      children: [
        Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTapDown:
                showProgress || generator.count < 1 ? null : startProgress,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        generator.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('Owned: ${generator.count}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(generator.description),
                  Text(
                    'Produces: ${toLettersNotation(generator.baseOutput)} coins/sec',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cost: ${toLettersNotation(generator.cost)} coins',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              widget.gameState.coins.count >= generator.cost
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                      ElevatedButton(
                        onPressed:
                            widget.gameState.coins.count >= generator.cost
                                ? () =>
                                    widget.gameState.buyCoinGenerator(generator)
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade400,
                          foregroundColor: Colors.black,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Buy',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showProgress)
                    AnimatedContainer(
                      duration: Duration(milliseconds: duration),
                      height: 5,
                      width: progress * (screenWidth - 32), // Expanding bar
                      color: Colors.blue,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
