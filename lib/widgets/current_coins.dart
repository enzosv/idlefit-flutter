import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:idlefit/providers/game_engine_provider.dart';
import '../util.dart';

/// Provider that combines the game tick and coin count to ensure consistent updates
final currentCoinValueProvider = Provider<double>((ref) {
  // Watch the game tick stream to rebuild when the game loop runs
  final tickStatus = ref.watch(gameTickProvider);

  tickStatus.whenData((_) {
    print("Current coin value rebuilding due to game tick");
  });

  // Get the current coin value
  final currencies = ref.watch(currencyNotifierProvider);
  final coinValue = currencies[CurrencyType.coin]?.count ?? 0;
  print("Current coin value: $coinValue");
  return coinValue;
});

class CurrentCoins extends ConsumerStatefulWidget {
  static final globalKey = GlobalKey<_CurrentCoinsState>();

  const CurrentCoins({super.key});

  static void triggerAnimation() {
    globalKey.currentState?._triggerAnimation();
  }

  @override
  ConsumerState<CurrentCoins> createState() => _CurrentCoinsState();
}

class _CurrentCoinsState extends ConsumerState<CurrentCoins>
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
    // Get coin value from the combined provider that watches the game tick
    final coinCount = ref.watch(currentCoinValueProvider);
    print("CurrentCoins widget rebuilding with value: $coinCount");

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Text(
            toLettersNotation(coinCount),
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
