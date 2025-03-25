import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/helpers/constants.dart';
import 'package:idlefit/providers/providers.dart';
import '../models/shop_items.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void resume() {
    if (!_isPaused) return;
    print("resumed");

    _isPaused = false;

    _gameLoopTimer = Timer.periodic(
      const Duration(milliseconds: Constants.tickTime),
      (_) => _processGenerators(),
    );

    // TODO: reset background activity
  }

  void pause() {
    _gameLoopTimer?.cancel();
    _isPaused = true;
    print("paused");
  }

  void _processGenerators() {
    if (_isPaused) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final realDif = now - _lastGenerated;

    final gameStateNotifier = ref.read(gameStateProvider.notifier);
    final dif = gameStateNotifier.calculateValidTimeSinceLastGenerate(
      now,
      _lastGenerated,
    );

    // Handle coin generation
    double coinsGenerated = gameStateNotifier.passiveOutput;
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
    gameStateNotifier.updateBackgroundActivity(dif.toDouble(), coinsGenerated);
  }
}
