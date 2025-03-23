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
  bool loading = false;
  @override
  void initState() {
    super.initState();
  }

  void _watchAd() {
    // TODO: add loading state
    // TODO: DRY up against shop_double_coin_card
    AdService.showRewardedAd(
      onRewarded: () {
        // double coin boost
        ref
            .read(gameStateProvider.notifier)
            .setDoubleCoinExpiry(
              DateTime.now()
                  .add(const Duration(seconds: 10))
                  .millisecondsSinceEpoch,
            );
        // update quest
        ref
            .read(questStatsRepositoryProvider)
            .progressTowards(
              QuestAction.watch,
              QuestUnit.ad,
              todayTimestamp,
              1,
            );
      },
      onAdDismissed: () {
        // Ad was dismissed without reward
      },
      onAdFailedToShow: (error) {
        debugPrint('Failed to show ad: $error');
      },
    ).then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(),
        ),
      );
    }
    final gameState = ref.watch(gameStateProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeLeft = (gameState.doubleCoinExpiry - now) ~/ 1000;
    if (timeLeft > 0) {
      // show countdown
      final minutes = timeLeft ~/ 60;
      final seconds = timeLeft % 60;
      return Text(
        "2x $minutes:${seconds.toString().padLeft(2, '0')}",
        style: TextStyle(fontSize: 12, color: CurrencyType.coin.color),
      );
    }
    // show boost button
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
