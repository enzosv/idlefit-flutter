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
  bool showIcon = false;
  late AnimationController _iconController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _positionAnimation;
  final duration = 500;
  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-2, -3), // Move diagonally towards top-left
    ).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOutCubic),
    );
  }

  void startProgress() {
    if (showProgress ||
        widget.gameState.coinGenerators[widget.generatorIndex].count < 1) {
      return;
    }
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
        showIcon = true;
      }); // Hide bar after animation completes
      _iconController.forward(from: 0.0); // Start icon animation
      _showFloatingIcon(context);

      Future.delayed(Duration(milliseconds: duration), () {
        setState(() => showIcon = false); // Hide icon after animation
      });

      final generator = widget.gameState.coinGenerators[widget.generatorIndex];
      widget.gameState.coins.earn(generator.tapOutput);
    });
  }

  void _showFloatingIcon(BuildContext context) {
    if (!mounted) return;
    final size = 24.0;
    final overlay = Overlay.of(context);
    final RenderBox? cardRenderBox = context.findRenderObject() as RenderBox?;
    if (cardRenderBox == null) return;

    final cardPosition = cardRenderBox.localToGlobal(Offset.zero);
    final cardCenterX = cardPosition.dx + (cardRenderBox.size.width / 2);
    final cardCenterY = cardPosition.dy + (cardRenderBox.size.height / 2);

    final overlayEntry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: _iconController,
          builder: (context, child) {
            return Positioned(
              left: cardCenterX,
              top: cardCenterY,
              child: Transform.translate(
                offset: Offset(
                  _positionAnimation.value.dx * 48,
                  _positionAnimation.value.dy * 160,
                ),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Icon(Icons.star, color: Colors.yellow, size: size),
                ),
              ),
            );
          },
        );
      },
    );
    overlay.insert(overlayEntry);

    Future.delayed(Duration(milliseconds: 800), () {
      overlayEntry.remove();
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
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
            onTap: showProgress || generator.count < 1 ? null : startProgress,
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
                        child: const Text('Buy'),
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
