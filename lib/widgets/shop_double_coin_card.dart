import 'dart:async';
import 'package:flutter/material.dart';
import 'package:idlefit/services/ad_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_state.dart';
import '../models/shop_items.dart';
import 'common_card.dart';

class DoubleCoinsCard extends ConsumerStatefulWidget {
  final ShopItem item;

  const DoubleCoinsCard({super.key, required this.item});

  @override
  ConsumerState<DoubleCoinsCard> createState() => _DoubleCoinsCardState();
}

class _DoubleCoinsCardState extends ConsumerState<DoubleCoinsCard> {
  Timer? _timer;
  int _timeLeft = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    // Update immediately
    _updateTimeLeft();

    // Then start periodic updates if needed
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    final gameState = ref.read(gameStateProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final isActive = gameState.doubleCoinExpiry > now;

    setState(() {
      _timeLeft = isActive ? (gameState.doubleCoinExpiry - now) ~/ 1000 : 0;
    });

    // Stop timer if boost is no longer active
    if (!isActive && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _watchAd() {
    final gameStateNotifier = ref.read(gameStateProvider.notifier);
    final gameState = ref.read(gameStateProvider);

    AdService.showRewardedAd(
      onRewarded: () {
        // Update via the notifier
        gameState.doubleCoinExpiry =
            DateTime.now()
                .add(const Duration(minutes: 1))
                .millisecondsSinceEpoch;
        gameStateNotifier.update();
        _startTimer();
      },
      onAdDismissed: () {
        // Ad was dismissed without reward
      },
      onAdFailedToShow: (error) {
        debugPrint('Failed to show ad: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final isActive = gameState.doubleCoinExpiry > now;
    final minutes = _timeLeft ~/ 60;
    final seconds = _timeLeft % 60;

    return CommonCard(
      title: widget.item.name,
      rightText: '', // Empty string since we don't want to show level
      description: widget.item.description,
      additionalInfo:
          isActive
              ? [
                Text(
                  'Time left: ${minutes}m ${seconds.toString().padLeft(2, '0')}s',
                ),
              ]
              : [],
      buttonText: isActive ? 'ACTIVE' : 'Watch Ad',
      onButtonPressed: isActive ? null : () => _watchAd(),
    );
  }
}
