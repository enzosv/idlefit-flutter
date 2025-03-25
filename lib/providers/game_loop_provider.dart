import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/helpers/constants.dart';
import 'package:idlefit/providers/providers.dart';
import '../models/shop_items.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class GameLoopNotifier extends Notifier<void> {
  Timer? _gameLoopTimer;
  int _lastGenerated = 0;
  bool _isPaused = true;

  @override
  void build() {
    initialize();
    ref.onDispose(() {
      _gameLoopTimer?.cancel(); // Ensure cleanup on hot-reload (dev only)
    });
    return;
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _lastGenerated = prefs.getInt('lastGenerated') ?? 0;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastGenerated', _lastGenerated);
  }

  void resume() {
    if (!_isPaused) return;
    print("resumed");

    _isPaused = false;

    _gameLoopTimer = Timer.periodic(
      const Duration(milliseconds: Constants.tickTime),
      (_) => _processGenerators(),
    );
  }

  void pause() {
    if (_isPaused) return;
    _gameLoopTimer?.cancel();
    _isPaused = true;
    print("paused");
    _scheduleCoinCapacityNotification();
    final gameStateNotifier = ref.read(gameStateProvider.notifier);
    gameStateNotifier.resetBackgroundActivity();
    gameStateNotifier.save();
  }

  void _processGenerators() {
    if (_isPaused) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final realDif = now - _lastGenerated;

    final gameStateNotifier = ref.read(gameStateProvider.notifier);
    final dif = _calculateValidTimeSinceLastGenerate(now, _lastGenerated);

    // Handle coin generation
    double coinsGenerated = ref.read(gameStateProvider).passiveOutput;
    assert(
      coinsGenerated ==
          ref.read(gameStateProvider.notifier).computePassiveOutput(),
      "coin generation is inconsistent",
    );
    if (coinsGenerated <= 0) {
      // no coins generated, skip
      return;
    }
    _lastGenerated = now;
    coinsGenerated *= (dif / Constants.tickTime);
    final coinsNotifier = ref.read(coinProvider.notifier);
    if (realDif < Constants.inactiveThreshold) {
      // don't use energy
      // earn coins
      coinsNotifier.earn(coinsGenerated);
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
    gameStateNotifier.updateBackgroundActivity(
      energySpent: dif.toDouble(),
      coinsEarned: coinsGenerated,
    );
  }

  /// **Calculate Valid Time Since Last Generate**
  int _calculateValidTimeSinceLastGenerate(int now, int previous) {
    if (previous <= 0) {
      return Constants.tickTime;
    }
    final dif = now - previous;
    assert(dif > 0, "previous should not be in the future");

    if (dif < Constants.inactiveThreshold) {
      // even if app became inactive, it wasn't long enough. don't limit to energy
      return dif;
    }
    // TODO: what if energy is synced late?
    // limit to energy
    // if dif > energy
    // take note of this attempt
    // when new health data is synced
    // compare if calorie burn time is within this attempt time
    // if so, grant user coins based on current passive output and available energy
    return min(dif, ref.read(energyProvider).count.floor());
  }

  /// **Calculate Passive Output**

  void _scheduleCoinCapacityNotification() {
    final coins = ref.read(coinProvider);
    if (coins.count >= coins.max) return;

    final coinsToFill = coins.max - coins.count;

    final passiveOutput = ref.read(gameStateProvider).passiveOutput;
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
}
