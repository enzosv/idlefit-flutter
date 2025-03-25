import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/helpers/constants.dart';
import 'package:idlefit/models/background_activity.dart';
import 'package:idlefit/services/game_state.dart';
import 'package:objectbox/objectbox.dart';
import '../models/shop_items.dart';
import '../services/notification_service.dart';
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
      isPaused: true,
      lastGenerated: 0,
      doubleCoinExpiry: 0,
      healthLastSynced: 0,
      backgroundActivity: BackgroundActivity(),
    );
  }

  Future<void> initialize(Store objectBoxService) async {
    // Try to load saved state
    final savedState = await state.loadGameState();

    state = state.copyWith(
      lastGenerated: savedState['lastGenerated'] ?? 0,
      doubleCoinExpiry: savedState['doubleCoinExpiry'] ?? 0,
      healthLastSynced: savedState['healthLastSynced'] ?? 0,
      backgroundActivity: BackgroundActivity(),
    );
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

  // main run loop
  // void _processGenerators() {
  //   if (state.isPaused) return;
  //   final now = DateTime.now().millisecondsSinceEpoch;
  //   final realDif = now - state.lastGenerated;
  //   final dif = _calculateValidTimeSinceLastGenerate(now, state.lastGenerated);

  //   // Handle coin generation
  //   double coinsGenerated = passiveOutput;
  //   if (coinsGenerated <= 0) {
  //     // no coins generated, skip
  //     return;
  //   }
  //   coinsGenerated *= (dif / Constants.tickTime);
  //   final coinsNotifier = ref.read(coinProvider.notifier);
  //   if (realDif < Constants.inactiveThreshold) {
  //     // don't use energy
  //     // earn coins
  //     coinsNotifier.earn(coinsGenerated);
  //     state = state.copyWith(lastGenerated: now);
  //     return;
  //   }
  //   // use energy
  //   // reduce coins generated offline
  //   coinsGenerated *= ref
  //       .read(shopItemProvider.notifier)
  //       .multiplier(ShopItemEffect.offlineCoinMultiplier);
  //   coinsNotifier.earn(coinsGenerated);

  //   // consume energy
  //   final energyNotifier = ref.read(energyProvider.notifier);
  //   energyNotifier.spend(dif.toDouble());
  //   // track energy spent for popup
  //   final newBackgroundActivity = state.backgroundActivity.copyWith(
  //     energySpent: dif.toDouble(),
  //     coinsEarned: coinsGenerated,
  //   );

  //   // update state
  //   state = state.copyWith(
  //     backgroundActivity: newBackgroundActivity,
  //     lastGenerated: now,
  //   );
  // }

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
    save();
  }

  void _scheduleCoinCapacityNotification() {
    final coins = ref.read(coinProvider);
    if (coins.count >= coins.max) return;

    final coinsToFill = coins.max - coins.count;

    final effectiveOutput =
        passiveOutput *
        ref
            .read(shopItemProvider.notifier)
            .multiplier(ShopItemEffect.offlineCoinMultiplier);
    if (effectiveOutput <= 0) return;

    final secondsToFill = coinsToFill / effectiveOutput;
    if (secondsToFill <= 0) return;

    final notificationTime = DateTime.now().add(
      Duration(seconds: secondsToFill.ceil()),
    );

    NotificationService.scheduleCoinCapacityNotification(
      id: Constants.notificationId,
      scheduledDate: notificationTime,
      title: 'Coin Capacity Full',
      body:
          'Your coins have reached maximum capacity! Time to upgrade or spend.',
    );
  }

  /// **Calculate Passive Output**
  double get passiveOutput {
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

  /// **Calculate Valid Time Since Last Generate**
  int calculateValidTimeSinceLastGenerate(int now, int previous) {
    if (previous <= 0) {
      return Constants.tickTime;
    }
    final dif = now - previous;
    if (dif < 0) {
      return Constants.tickTime;
    }

    if (dif < Constants.inactiveThreshold) {
      // even if app became inactive, it wasn't long enough. don't limit to energy
      return dif;
    }
    // limit to energy
    // if dif > energy
    // take note of this attempt
    // when new health data is synced
    // compare if calorie burn time is within this attempt time
    // if so, grant user coins based on current passive output and available energy
    return min(dif, ref.read(energyProvider).count.floor());
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

    state = state.copyWith(
      lastGenerated: 0,
      doubleCoinExpiry: 0,
      healthLastSynced: 0,
      backgroundActivity: null,
      isPaused: true,
    );

    await ref
        .read(healthServiceProvider)
        .syncHealthData(this, ref.read(questStatsRepositoryProvider), days: 1);

    ref.read(gameLoopProvider.notifier).resume();
  }
}
