import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/helpers/constants.dart';
import 'package:idlefit/models/background_activity.dart';
import 'package:idlefit/services/game_state.dart';
import 'package:objectbox/objectbox.dart';
import '../models/shop_items.dart';
import 'package:idlefit/providers/providers.dart';

class GameStateNotifier extends Notifier<GameState> {
  // Timer? _generatorTimer;

  @override
  GameState build() {
    // _startGenerators();
    // ref.onDispose(() {
    //   _generatorTimer?.cancel();
    // });
    return GameState(
      doubleCoinExpiry: 0,
      healthLastSynced: 0,
      passiveOutput: 0,
      backgroundActivity: BackgroundActivity(),
    );
  }

  Future<void> initialize(Store objectBoxService) async {
    // Try to load saved state
    final savedState = await state.loadGameState();
    state = state.copyWith(
      doubleCoinExpiry: savedState['doubleCoinExpiry'] ?? 0,
      healthLastSynced: savedState['healthLastSynced'] ?? 0,
      backgroundActivity: BackgroundActivity(),
    );
    /**
     * not initializing passiveoutput yet
     * have to wait for
     * double coin expiry
     * generators to load
     * shop items to load
     */
  }

  double computePassiveOutput() {
    final generators = ref.read(generatorProvider);
    double output = generators.fold(
      0,
      (sum, generator) => sum + generator.output,
    );
    double coinMultiplier = ref
        .read(shopItemProvider.notifier)
        .multiplier(ShopItemEffect.coinMultiplier);
    if (state.doubleCoinExpiry >= DateTime.now().millisecondsSinceEpoch) {
      // TODO: what if doubler is active for part of the time?
      coinMultiplier += 1;
    }
    return output * coinMultiplier;
  }

  /// must be recomputed after every generator, shop, upgrade, buy
  /// must be recomputed after ad watch
  void recomputePassiveOutput() {
    final passiveOutput = computePassiveOutput();
    if (passiveOutput == state.passiveOutput) {
      return;
    }
    state = state.copyWith(passiveOutput: passiveOutput);
    save();
  }

  void resetBackgroundActivity() {
    state = state.copyWith(backgroundActivity: BackgroundActivity());
  }

  void save() async {
    state.saveGameState();
    ref.read(currencyRepoProvider).saveCurrencies([
      ref.read(coinProvider),
      ref.read(energyProvider),
      ref.read(spaceProvider),
    ]);
    // not saving generators and shopitems. only changes on buy anyway
  }

  Future<void> convertHealthStats(int steps, double calories) async {
    assert(
      steps > 0 || calories > 0,
      "do not convert when there is nothing to convert",
    );
    state = state.copyWith(
      healthLastSynced: DateTime.now().millisecondsSinceEpoch,
    );
    final healthMultiplier = ref
        .read(shopItemProvider.notifier)
        .multiplier(ShopItemEffect.healthMultiplier);
    final energyGain =
        calories * healthMultiplier * Constants.calorieToEnergyMultiplier;
    final spaceGain =
        steps * healthMultiplier * Constants.stepsToSpaceMultiplier;

    if (spaceGain > 0) {
      ref.read(spaceProvider.notifier).earn(spaceGain);
    }
    if (energyGain > 0) {
      ref.read(energyProvider.notifier).earn(energyGain);
    }
    if (state.backgroundActivity.energySpent <= 0) {
      state = state.copyWith(
        healthLastSynced: DateTime.now().millisecondsSinceEpoch,
      );
      save();
      return;
    }
    updateBackgroundActivity(energyEarned: energyGain, spaceEarned: spaceGain);
    save();
  }

  Future<void> updateBackgroundActivity({
    double? energyEarned,
    double? spaceEarned,
    double? energySpent,
    double? coinsEarned,
  }) async {
    final newBackgroundActivity = state.backgroundActivity.copyWith(
      energyEarned: energyEarned ?? 0,
      spaceEarned: spaceEarned ?? 0,
      energySpent: energySpent ?? 0,
      coinsEarned: coinsEarned ?? 0,
    );
    state = state.copyWith(backgroundActivity: newBackgroundActivity);
  }

  void setDoubleCoinExpiry(int expiry) {
    state = state.copyWith(doubleCoinExpiry: expiry);
    recomputePassiveOutput();
  }

  Future<void> fullReset() async {
    ref.read(gameLoopProvider.notifier).pause();
    [
      ref.read(generatorProvider.notifier).reset(),
      ref.read(questStatsRepositoryProvider).box.removeAllAsync(),
      ref.read(currencyRepoProvider).reset(),
      ref.read(shopItemProvider.notifier).reset(),
      ref.read(questRepositoryProvider).box.removeAllAsync(),
    ].wait;
    ref.read(coinProvider.notifier).reset();
    ref.read(spaceProvider.notifier).reset();
    ref.read(energyProvider.notifier).reset();

    // TODO: reset loop

    state = state.copyWith(
      doubleCoinExpiry: 0,
      healthLastSynced: 0,
      backgroundActivity: null,
    );

    await ref
        .read(healthServiceProvider)
        .syncHealthData(this, ref.read(questStatsRepositoryProvider), days: 1);

    ref.read(gameLoopProvider.notifier).resume();
  }
}
