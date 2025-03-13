import 'dart:async';
import 'package:idlefit/constants.dart';
import 'package:idlefit/main.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/shop_items_repo.dart';
import 'package:idlefit/models/currency_repo.dart';
import 'package:idlefit/services/game_state.dart';
import 'package:objectbox/objectbox.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';
import '../models/shop_items.dart';
import 'dart:math';
import 'notification_service.dart';

class GameStateNotifier extends StateNotifier<GameState> {
  Timer? _generatorTimer;

  GameStateNotifier(super.state) {
    _startGenerators();
  }

  Future<void> initialize(
    StorageService storageService,
    Store objectBoxService,
  ) async {
    // Load data from repositories
    final coinGenerators = await state.generatorRepo.parseCoinGenerators(
      'assets/coin_generators.json',
    );
    final shopItems = await state.shopItemRepo.parseShopItems(
      'assets/shop_items.json',
    );

    // Ensure default currencies exist and load them
    state.currencyRepo.ensureDefaultCurrencies();
    final currencies = state.currencyRepo.loadCurrencies();
    final coins = currencies[CurrencyType.coin]!;
    final gems = currencies[CurrencyType.gem]!;
    final energy = currencies[CurrencyType.energy]!;
    final space = currencies[CurrencyType.space]!;

    // Try to load saved state
    final savedState = await storageService.loadGameState();

    state = state.copyWith(
      coins: coins,
      gems: gems,
      energy: energy,
      space: space,
      coinGenerators: coinGenerators,
      shopItems: shopItems,
      lastGenerated: savedState?['lastGenerated'] ?? 0,
      offlineCoinMultiplier: savedState?['offlineCoinMultiplier'] ?? 0.5,
      doubleCoinExpiry: savedState?['doubleCoinExpiry'] ?? 0,
      backgroundState: {
        'coins': coins.count,
        'energy': 0,
        'space': 0,
        'energySpent': 0,
      },
    );
  }

  void setIsPaused(bool isPaused) {
    state = state.copyWith(isPaused: isPaused);
    // state.save();
  }

  void _startGenerators() {
    final duration = Duration(milliseconds: Constants.tickTime);
    _generatorTimer = Timer.periodic(duration, (_) {
      _processGenerators();
    });
  }

  void _processGenerators() {
    if (state.isPaused) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final realDif = state.lastGenerated - now;
    final dif = state.calculateValidTimeSinceLastGenerate(
      now,
      state.lastGenerated,
    );

    // Handle coin generation
    double coinsGenerated = state.passiveOutput;
    if (coinsGenerated <= 0) {
      // no coins generated, skip
      return;
    }
    coinsGenerated *= (dif / Constants.tickTime);

    var newState = state;
    if (realDif > Constants.inactiveThreshold && dif > Constants.tickTime) {
      // consume energy
      final newEnergy = newState.energy.spend(dif.toDouble());
      assert(newEnergy != null, "energy spent is more than available");
      // reduce coins generated offline
      coinsGenerated *= state.offlineCoinMultiplier;

      // track energy spent for popup
      final newBackgroundState = Map<String, double>.from(
        state.backgroundState,
      );
      newBackgroundState['energySpent'] = dif.toDouble();

      // update state
      newState = newState.copyWith(
        energy: newEnergy,
        backgroundState: newBackgroundState,
      );
    }

    // earn coins
    final newCoins = newState.coins.earn(coinsGenerated);
    state = newState.copyWith(coins: newCoins, lastGenerated: now);
    state.save();
  }

  void convertHealthStats(
    double steps,
    double calories,
    double exerciseMinutes,
  ) {
    double healthMultiplier = 1.0;
    for (final item in state.shopItems) {
      if (item.shopItemEffect == ShopItemEffect.healthMultiplier) {
        healthMultiplier += item.effectValue * item.level;
      }
    }

    final energyGain =
        calories * healthMultiplier * Constants.calorieToEnergyMultiplier;
    final gemGain = exerciseMinutes * healthMultiplier / 2;

    final newBackgroundState = Map<String, double>.from(state.backgroundState);
    newBackgroundState['energy'] = energyGain;
    newBackgroundState['space'] = steps;

    state = state.copyWith(
      energy: state.energy.earn(energyGain),
      gems: state.gems.earn(gemGain),
      space: state.space.earn(steps),
      backgroundState: newBackgroundState,
    );

    state.save();
  }

  void saveBackgroundState() {
    state = state.copyWith(backgroundState: state.getBackgroundStateSnapshot());
    _scheduleCoinCapacityNotification();
  }

  @override
  void dispose() {
    _generatorTimer?.cancel();
    super.dispose();
  }

  void earnCurrency(CurrencyType currencyType, double amount) {
    switch (currencyType) {
      case CurrencyType.coin:
        final newCoins = state.coins.earn(amount);
        state = state.copyWith(coins: newCoins);
      case CurrencyType.space:
        final newSpace = state.space.earn(amount);
        state = state.copyWith(space: newSpace);
      case CurrencyType.energy:
        final newEnergy = state.energy.earn(amount);
        state = state.copyWith(energy: newEnergy);
      case CurrencyType.gem:
        final newGems = state.gems.earn(amount);
        state = state.copyWith(gems: newGems);
      default:
        return;
    }
    state.save();
  }

  void setDoubleCoinExpiry(int expiry) {
    state = state.copyWith(doubleCoinExpiry: expiry);
    state.save();
  }

  void _scheduleCoinCapacityNotification() {
    if (state.coins.count >= state.coins.max) return;

    final coinsToFill = state.coins.max - state.coins.count;
    final effectiveOutput = state.passiveOutput * state.offlineCoinMultiplier;
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

  bool buyCoinGenerator(CoinGenerator generator) {
    final newCoins = state.coins.spend(generator.cost);
    if (newCoins == null) return false;

    var newState = state.copyWith(coins: newCoins);

    if (generator.count == 0) {
      final next = state.coinGenerators[generator.tier].cost;
      final newMax = max(next, (200 * pow(10, generator.tier - 1)).toDouble());

      newState = newState.copyWith(
        coins: newState.coins.copyWith(baseMax: newMax),
      );

      if (generator.tier % 10 == 0) {
        newState = newState.copyWith(
          gems: newState.gems.copyWith(baseMax: newState.gems.baseMax + 10),
        );
      }

      if (generator.tier % 5 == 0 && newState.energy.baseMax < 86400000) {
        newState = newState.copyWith(
          energy: newState.energy.copyWith(
            baseMax: newState.energy.baseMax + 3600000,
          ),
        );
      }
    }

    generator.count++;
    state.generatorRepo.saveCoinGenerator(generator);

    state = newState;
    state.save();
    return true;
  }

  bool upgradeShopItem(ShopItem item) {
    if (item.id == 4 || item.level >= item.maxLevel) return false;

    final newSpace = state.space.spend(item.currentCost.toDouble());
    if (newSpace == null) return false;

    item.level++;
    var newState = state.copyWith(space: newSpace);

    switch (item.shopItemEffect) {
      case ShopItemEffect.spaceCapacity:
        newState = newState.copyWith(
          space: newState.space.copyWith(
            maxMultiplier: newState.space.maxMultiplier + item.effectValue,
          ),
        );
      case ShopItemEffect.energyCapacity:
        newState = newState.copyWith(
          energy: newState.energy.copyWith(
            maxMultiplier: newState.energy.maxMultiplier + item.effectValue,
          ),
        );
      case ShopItemEffect.offlineCoinMultiplier:
        newState = newState.copyWith(
          offlineCoinMultiplier:
              newState.offlineCoinMultiplier + item.effectValue,
        );
      case ShopItemEffect.coinCapacity:
        newState = newState.copyWith(
          coins: newState.coins.copyWith(
            maxMultiplier: newState.coins.maxMultiplier + item.effectValue,
          ),
        );
      default:
        break;
    }

    state = newState;
    state.shopItemRepo.saveShopItem(item);
    state.save();
    return true;
  }

  bool unlockGenerator(CoinGenerator generator) {
    if (generator.count < 10 || generator.isUnlocked) return false;

    final newSpace = state.space.spend(generator.upgradeUnlockCost);
    if (newSpace == null) return false;

    generator.isUnlocked = true;
    state.generatorRepo.saveCoinGenerator(generator);

    state = state.copyWith(space: newSpace);
    state.save();
    return true;
  }

  bool upgradeGenerator(CoinGenerator generator) {
    if (generator.count < 10 || !generator.isUnlocked) return false;

    final newCoins = state.coins.spend(generator.upgradeCost);
    if (newCoins == null) return false;

    generator.level++;
    state.generatorRepo.saveCoinGenerator(generator);

    state = state.copyWith(coins: newCoins);
    state.save();
    return true;
  }
}

// Create providers
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((
  ref,
) {
  final store =
      ref
          .read(objectBoxProvider)
          .store; // You'll need to properly initialize this
  final storageService = ref.read(storageServiceProvider);
  return GameStateNotifier(
    GameState(
      isPaused: true,
      coins: Currency(
        id: CurrencyType.coin.index,
        count: 0,
        baseMax: 0,
        maxMultiplier: 1,
      ),
      gems: Currency(
        id: CurrencyType.gem.index,
        count: 0,
        baseMax: 0,
        maxMultiplier: 1,
      ),
      energy: Currency(
        id: CurrencyType.energy.index,
        count: 0,
        baseMax: 0,
        maxMultiplier: 1,
      ),
      space: Currency(
        id: CurrencyType.space.index,
        count: 0,
        baseMax: 0,
        maxMultiplier: 1,
      ),
      lastGenerated: 0,
      doubleCoinExpiry: 0,
      offlineCoinMultiplier: 0.5,
      coinGenerators: [],
      shopItems: [],
      storageService: storageService,
      currencyRepo: CurrencyRepo(box: store.box<Currency>()),
      generatorRepo: CoinGeneratorRepo(box: store.box<CoinGenerator>()),
      shopItemRepo: ShopItemsRepo(box: store.box<ShopItem>()),
    ),
  );
});
