import 'dart:async';
import 'package:flutter/material.dart';
import 'package:idlefit/services/ad_service.dart';
import 'package:provider/provider.dart';
import '../services/game_state.dart';
import '../models/shop_items.dart';
import 'common_card.dart';

class DoubleCoinsCard extends StatefulWidget {
  final ShopItem item;

  const DoubleCoinsCard({super.key, required this.item});

  @override
  State<DoubleCoinsCard> createState() => _DoubleCoinsCardState();
}

class _DoubleCoinsCardState extends State<DoubleCoinsCard> {
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
    final gameState = Provider.of<GameState>(context, listen: false);
    final now = DateTime.now().millisecondsSinceEpoch;
    final isActive = gameState.playerStats.doubleCoinExpiry > now;

    setState(() {
      _timeLeft =
          isActive ? (gameState.playerStats.doubleCoinExpiry - now) ~/ 1000 : 0;
    });

    // Stop timer if boost is no longer active
    if (!isActive && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _watchAd(GameState gameState) {
    AdService.showRewardedAd(
      onRewarded: () {
        gameState.playerStats.doubleCoinExpiry =
            DateTime.now()
                .add(const Duration(minutes: 1))
                .millisecondsSinceEpoch;
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
    final gameState = Provider.of<GameState>(context);
    final now = DateTime.now().millisecondsSinceEpoch;
    final isActive = gameState.playerStats.doubleCoinExpiry > now;
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
      onButtonPressed: isActive ? null : () => _watchAd(gameState),
    );
  }
}
