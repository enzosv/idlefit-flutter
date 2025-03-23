import 'dart:async';
import 'package:flutter/material.dart';
import 'package:idlefit/helpers/constants.dart';
import 'package:idlefit/helpers/util.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/models/quest_stats.dart';
import 'package:idlefit/services/ad_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/providers/game_state_provider.dart';

class BoostButton extends ConsumerStatefulWidget {
  const BoostButton({super.key});

  @override
  ConsumerState<BoostButton> createState() => _BoostButtonState();
}

class _BoostButtonState extends ConsumerState<BoostButton> {
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
    AdService.showRewardedAd(
      onRewarded: () {
        ref
            .read(gameStateProvider.notifier)
            .setDoubleCoinExpiry(
              DateTime.now()
                  .add(const Duration(minutes: 1))
                  .millisecondsSinceEpoch,
            );
        ref
            .read(questStatsRepositoryProvider)
            .progressTowards(
              QuestAction.watch,
              QuestUnit.ad,
              todayTimestamp,
              1,
            );
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
    if (isActive) {
      final minutes = _timeLeft ~/ 60;
      final seconds = _timeLeft % 60;
      return Text(
        "2x $minutes:${seconds.toString().padLeft(2, '0')}",
        style: TextStyle(fontSize: 12, color: CurrencyType.coin.color),
      );
    }
    return OutlinedButton.icon(
      onPressed: () {
        _watchAd();
      },
      label: Text(""),
      icon: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.play_circle),
          Text("Boost", style: TextStyle(fontSize: 12, color: Colors.white)),
        ],
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: Constants.primaryColor,
        foregroundColor: Colors.white,
        iconSize: 12,
        padding: const EdgeInsets.only(left: 4),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(0, 0),
        side: BorderSide(color: CurrencyType.coin.color),
      ),
    );
  }
}
