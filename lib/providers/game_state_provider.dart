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
    // have to wait for double coin expiry to be part of state before computing
    recomputePassiveOutput();
  }

  double computePassiveOutput() {
    final generators = ref.watch(generatorProvider);
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

  // void setIsPaused(bool isPaused) {
  //   state = state.copyWith(isPaused: isPaused);
  //   if (!isPaused) {
  //     return;
  //   }
  //   resetBackgroundActivity();
  //   save();
  //   _scheduleCoinCapacityNotification();
  // }

  void resetBackgroundActivity() {
    state = state.copyWith(backgroundActivity: BackgroundActivity());
  }

  // void _startGenerators() {
  //   final duration = Duration(milliseconds: Constants.tickTime);
  //   _generatorTimer = Timer.periodic(duration, (_) {
  //     _processGenerators();
  //   });
  // }

  void save() async {
    state.saveGameState();
    ref.read(currencyRepoProvider).saveCurrencies([
      ref.read(coinProvider),
      ref.read(energyProvider),
      ref.read(spaceProvider),
    ]);
    // not saving generators and shopitems. only changes on buy anyway
  }

  void updateBackgroundActivity(double energySpent, double coinsEarned) {
    final newBackgroundActivity = state.backgroundActivity.copyWith(
      energySpent: energySpent,
      coinsEarned: coinsEarned,
    );
    state = state.copyWith(backgroundActivity: newBackgroundActivity);
  }

  Future<void> convertHealthStats(int steps, double calories) async {
    if (steps <= 0 && calories <= 0) {
      state = state.copyWith(
        healthLastSynced: DateTime.now().millisecondsSinceEpoch,
      );
      return;
    }
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
    print("generating background activity");
    final newBackgroundActivity = state.backgroundActivity.copyWith(
      energyEarned: energyGain,
      spaceEarned: spaceGain,
    );
    print('newBackgroundActivity: $newBackgroundActivity');

    state = state.copyWith(
      backgroundActivity: newBackgroundActivity,
      healthLastSynced: DateTime.now().millisecondsSinceEpoch,
    );
    print("updated state");
    save();
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
