import 'dart:async';
import 'package:idlefit/helpers/constants.dart';
import 'package:idlefit/models/currency_repo.dart';
import 'package:idlefit/models/quest_stats.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:idlefit/providers/generator_provider.dart';
import 'package:idlefit/providers/shop_item_provider.dart';
import 'package:idlefit/models/background_activity.dart';
import 'package:idlefit/services/game_state.dart';
import 'package:objectbox/objectbox.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shop_items.dart';
import 'dart:math';
import '../services/notification_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameStateNotifier extends StateNotifier<GameState> {
  static const _gameStateKey = 'game_state';
  final Ref ref;
  Timer? _generatorTimer;
  late final SharedPreferences _prefs;

  GameStateNotifier(this.ref, super.state) {
    _startGenerators();
  }

  Future<void> initialize(Store objectBoxService) async {
    _prefs = await SharedPreferences.getInstance();

    // Try to load saved state
    final savedState = await loadGameState();

    state = state.copyWith(
      lastGenerated: savedState?['lastGenerated'] ?? 0,
      doubleCoinExpiry: savedState?['doubleCoinExpiry'] ?? 0,
      backgroundActivity: BackgroundActivity(),
    );
  }

  void setIsPaused(bool isPaused) {
    state = state.copyWith(isPaused: isPaused);
    if (isPaused) {
      resetBackgroundActivity();
      save();
      _scheduleCoinCapacityNotification();
    }
  }

  void resetBackgroundActivity() {
    state = state.copyWith(backgroundActivity: BackgroundActivity());
  }

  void _startGenerators() {
    final duration = Duration(milliseconds: Constants.tickTime);
    _generatorTimer = Timer.periodic(duration, (_) {
      _processGenerators();
    });
  }

  void save() async {
    saveGameState(state.toJson());
    ref.read(currencyRepoProvider).saveCurrencies([
      ref.read(coinProvider),
      ref.read(gemProvider),
      ref.read(energyProvider),
      ref.read(spaceProvider),
    ]);
    // not saving generators and shopitems. only changes on buy anyway
  }

  // main run loop
  void _processGenerators() {
    if (state.isPaused) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final realDif = now - state.lastGenerated;
    final dif = _calculateValidTimeSinceLastGenerate(now, state.lastGenerated);

    // Handle coin generation
    double coinsGenerated = passiveOutput;
    if (coinsGenerated <= 0) {
      // no coins generated, skip
      return;
    }
    coinsGenerated *= (dif / Constants.tickTime);
    final coinsNotifier = ref.read(coinProvider.notifier);
    if (realDif < Constants.inactiveThreshold) {
      // don't use energy
      // earn coins
      coinsNotifier.earn(coinsGenerated);
      state = state.copyWith(lastGenerated: now);
      return;
    }
    // use energy
    // reduce coins generated offline
    coinsGenerated *= ref
        .read(shopItemProvider.notifier)
        .multiplier(ShopItemEffect.offlineCoinMultiplier);
    coinsNotifier.earn(coinsGenerated);

    // consume energy
    final energyNotifier = ref.read(energyProvider.notifier);
    energyNotifier.spend(dif.toDouble());
    // track energy spent for popup
    final newBackgroundActivity = state.backgroundActivity.copyWith(
      energySpent: dif.toDouble(),
      coinsEarned: coinsGenerated,
    );

    // update state
    state = state.copyWith(
      backgroundActivity: newBackgroundActivity,
      lastGenerated: now,
    );
  }

  Future<void> convertHealthStats(int steps, double calories) async {
    final healthMultiplier = ref
        .read(shopItemProvider.notifier)
        .multiplier(ShopItemEffect.healthMultiplier);

    final energyGain =
        calories * healthMultiplier * Constants.calorieToEnergyMultiplier;
    final spaceGain =
        steps * healthMultiplier * Constants.stepsToSpaceMultiplier;

    final newBackgroundActivity = state.backgroundActivity.copyWith(
      energyEarned: energyGain,
      spaceEarned: spaceGain,
    );
    if (steps > 0) {
      // Steps are already tracked by setProgress in HealthService
      ref.read(spaceProvider.notifier).earn(spaceGain);
    }
    if (calories > 0) {
      ref.read(energyProvider.notifier).earn(energyGain);
    }

    state = state.copyWith(backgroundActivity: newBackgroundActivity);

    save();
  }

  @override
  void dispose() {
    _generatorTimer?.cancel();
    super.dispose();
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
  int _calculateValidTimeSinceLastGenerate(int now, int previous) {
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
    ref.read(generatorProvider.notifier).reset();
    ref.read(questStatsRepositoryProvider).box.removeAll();
    ref.read(currencyRepoProvider).reset(ref);
    await _prefs.remove(_gameStateKey);
    await ref.read(shopItemProvider.notifier).reset();

    state = state.copyWith(
      lastGenerated: 0,
      doubleCoinExpiry: 0,
      backgroundActivity: null,
    );
    // TODO: fetch health data
  }

  /// **Save Game State**

  Future<void> saveGameState(Map<String, dynamic> gameState) async {
    await _prefs.setString(_gameStateKey, jsonEncode(gameState));
  }

  Future<Map<String, dynamic>?> loadGameState() async {
    final stateString = _prefs.getString(_gameStateKey);
    if (stateString == null) return null;

    try {
      return jsonDecode(stateString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}

// Create providers
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((
  ref,
) {
  return GameStateNotifier(
    ref,
    GameState(isPaused: true, lastGenerated: 0, doubleCoinExpiry: 0),
  );
});
