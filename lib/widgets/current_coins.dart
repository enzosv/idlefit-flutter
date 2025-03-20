import 'package:flutter/material.dart';

class CurrentCoins extends StatefulWidget {
  static final globalKey = GlobalKey<_CurrentCoinsState>();
  // final Currency coins;
  final String currentCoins;

  const CurrentCoins({super.key, required this.currentCoins});

  static void triggerAnimation() {
    globalKey.currentState?._triggerAnimation();
  }

  @override
  State<CurrentCoins> createState() => _CurrentCoinsState();
}

class _CurrentCoinsState extends State<CurrentCoins>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.3), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _triggerAnimation() {
    _animationController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Text(
            widget.currentCoins,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
