import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/player_stats.dart';
import 'package:idlefit/models/player_stats_repo.dart';
import 'package:idlefit/models/shop_items_repo.dart';
import 'package:idlefit/models/currency_repo.dart';
import 'package:idlefit/util.dart';
import 'package:objectbox/objectbox.dart';
import '../models/shop_items.dart';
import 'dart:math';
import 'notification_service.dart';

class GameState with ChangeNotifier {
  static const _tickTime = 1000; // miliseconds
  static const _inactiveThreshold = 30000; // 30 seconds in milliseocnds
  static const _calorieToEnergyMultiplier =
      72000.0; // 1 calorie = 72 seconds of idle fuel
  static const _notificationId = 1;

  bool isPaused = true;

  // Player stats (previously stored in SharedPreferences)
  late PlayerStats playerStats;

  late final Currency coins;
  late final Currency gems;
  late final Currency energy;
  late final Currency space;

  // Generators and shop items
  List<CoinGenerator> coinGenerators = [];
  List<ShopItem> shopItems = [];

  // For saving/loading
  late PlayerStatsRepo _playerStatsRepo;
  late CurrencyRepo _currencyRepo;
  late CoinGeneratorRepo _generatorRepo;
  late ShopItemsRepo _shopItemRepo;
  Timer? _autoSaveTimer;
  Timer? _generatorTimer;

  Future<void> initialize(Store objectBoxService) async {
    // Initialize repositories
    _currencyRepo = CurrencyRepo(box: objectBoxService.box<Currency>());
    _generatorRepo = CoinGeneratorRepo(
      box: objectBoxService.box<CoinGenerator>(),
    );
    _shopItemRepo = ShopItemsRepo(box: objectBoxService.box<ShopItem>());
    _playerStatsRepo = PlayerStatsRepo(
      box: objectBoxService.box<PlayerStats>(),
    );

    // Load data from repositories
    coinGenerators = await _generatorRepo.parseCoinGenerators(
      'assets/coin_generators.json',
    );
    shopItems = await _shopItemRepo.parseShopItems('assets/shop_items.json');

    // Ensure default currencies exist and load them
    _currencyRepo.ensureDefaultCurrencies();
    final currencies = _currencyRepo.loadCurrencies();
    coins = currencies[CurrencyType.coin]!;
    gems = currencies[CurrencyType.gem]!;
    energy = currencies[CurrencyType.energy]!;
    space = currencies[CurrencyType.space]!;

    // Load player stats
    playerStats = _playerStatsRepo.loadPlayerStats();
    playerStats.backgroundCoins = coins.count;

    // Start timers
    _startAutoSave();
    _startGenerators();
  }

  void save() {
    _playerStatsRepo.savePlayerStats(playerStats);
    _currencyRepo.saveCurrencies([coins, energy, gems, space]);
    // not saving generators and shopitems. only changes on buy anyway
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      save();
    });
  }

  void _startGenerators() {
    final duration = Duration(milliseconds: _tickTime);
    _generatorTimer = Timer.periodic(duration, (_) {
      _processGenerators();
    });
  }

  int validTimeSinceLastGenerate(int now, int previous) {
    if (energy.count <= 0 || previous <= 0) {
      return _tickTime;
    }

    int dif = now - previous;
    // if last generated > 30s, consume energy
    if (dif < _inactiveThreshold) {
      // do not consume energy
      return dif;
    }
    dif = min(dif, energy.count.round());
    // smelly to perform modification in get
    playerStats.backgroundEnergySpent = dif.toDouble();
    energy.spend(dif.toDouble());
    print("spent energy ${durationNotation(dif.toDouble())}");
    return dif;
  }

  // the main run loop
  void _processGenerators() {
    if (isPaused) {
      return;
    }
    int now = DateTime.now().millisecondsSinceEpoch;
    final realDif = playerStats.lastGenerated - now;
    final availableDif = validTimeSinceLastGenerate(
      now,
      playerStats.lastGenerated,
    );
    final usesEnergy = realDif > _inactiveThreshold;

    double coinsGenerated = passiveOutput;
    if (usesEnergy) {
      // reduce speed of coin generation in background
      coinsGenerated *= playerStats.offlineCoinMultiplier;
    }
    coinsGenerated *= (availableDif / _tickTime);

    if (coinsGenerated > 0) {
      coins.earn(coinsGenerated);
      notifyListeners();
    }

    playerStats.lastGenerated = now;
  }

  void convertHealthStats(double steps, calories, exerciseMinutes) {
    // Calculate health multiplier from upgrades
    double healthMultiplier = 1.0;
    for (final item in shopItems) {
      if (item.shopItemEffect == ShopItemEffect.healthMultiplier) {
        healthMultiplier += item.effectValue * item.level;
      }
    }

    playerStats.backgroundEnergy = energy.earn(
      calories * healthMultiplier * _calorieToEnergyMultiplier,
    );
    print("new energy ${playerStats.backgroundEnergy}");
    gems.earn(
      exerciseMinutes * healthMultiplier / 2,
    ); // 2 exercise minutes = 1 gem
    playerStats.backgroundSpace = space.earn(steps);
    save();
    notifyListeners();
  }

  bool buyCoinGenerator(CoinGenerator generator) {
    if (!coins.spend(generator.cost)) {
      return false;
    }
    if (generator.count == 0) {
      // raise maximums

      // 200*pow(10, generator.tier-1) or next tier cost * 1.8
      final next = coinGenerators[generator.tier].cost;
      coins.baseMax = max(next, (200 * pow(10, generator.tier - 1).toDouble()));

      if (generator.tier % 10 == 0) {
        // raise gem limit every 10
        gems.baseMax += 10;
      }
      if (generator.tier % 5 == 0) {
        // raise energy limit by 1hr every 5
        // limit to 24hrs
        if (energy.baseMax < 86400000) {
          energy.baseMax += 3600000;
        }
      }
    }
    generator.count++;

    _generatorRepo.saveCoinGenerator(generator);
    save();
    notifyListeners();
    return true;
  }

  bool upgradeShopItem(ShopItem item) {
    if (item.id == 4) {
      return false;
    }
    if (item.level >= item.maxLevel) return false;

    if (!space.spend(item.currentCost.toDouble())) {
      return false;
    }

    item.level++;
    switch (item.shopItemEffect) {
      case ShopItemEffect.spaceCapacity:
        space.maxMultiplier += item.effectValue;
      case ShopItemEffect.energyCapacity:
        energy.maxMultiplier += item.effectValue;
      case ShopItemEffect.offlineCoinMultiplier:
        playerStats.offlineCoinMultiplier += item.effectValue;
      case ShopItemEffect.coinCapacity:
        coins.maxMultiplier += item.effectValue;
      default:
        break;
    }
    save();
    _shopItemRepo.saveShopItem(item);
    notifyListeners();
    return true;
  }

  bool unlockGenerator(CoinGenerator generator) {
    if (generator.count < 10) return false;
    if (generator.isUnlocked) return false;

    if (!space.spend(generator.upgradeUnlockCost)) {
      return false;
    }

    generator.isUnlocked = true;
    _generatorRepo.saveCoinGenerator(generator);
    save();
    notifyListeners();
    return true;
  }

  bool upgradeGenerator(CoinGenerator generator) {
    if (generator.count < 10) return false;
    if (!generator.isUnlocked) return false;

    if (!coins.spend(generator.upgradeCost)) {
      return false;
    }

    generator.level++;
    _generatorRepo.saveCoinGenerator(generator);
    save();
    notifyListeners();
    return true;
  }

  void saveBackgroundState() {
    playerStats.updateBackgroundState(coins.count, energy.count, space.count);
    save();

    // Schedule notification for when coins will reach capacity
    _scheduleCoinCapacityNotification();
  }

  void _scheduleCoinCapacityNotification() {
    if (coins.count >= coins.max) return;

    final coinsToFill = coins.max - coins.count;
    final effectiveOutput = passiveOutput * playerStats.offlineCoinMultiplier;
    if (effectiveOutput <= 0) return;

    final secondsToFill = coinsToFill / effectiveOutput;
    if (secondsToFill <= 0) return;

    final notificationTime = DateTime.now().add(
      Duration(seconds: secondsToFill.ceil()),
    );

    NotificationService.scheduleCoinCapacityNotification(
      id: _notificationId,
      scheduledDate: notificationTime,
      title: 'Coin Capacity Full',
      body:
          'Your coins have reached maximum capacity! Time to upgrade or spend.',
    );
  }

  Map<String, double> getBackgroundDifferences() {
    return playerStats.getBackgroundDifferences(
      coins.count,
      energy.count,
      space.count,
    );
  }

  double get passiveOutput {
    double output = coinGenerators.fold(
      0,
      (sum, generator) => sum + generator.output,
    );
    double coinMultiplier = 1.0;
    if (playerStats.doubleCoinExpiry >= DateTime.now().millisecondsSinceEpoch) {
      // TODO: what if doubler is active for part of the time?
      coinMultiplier += 1;
    }
    for (final item in shopItems) {
      if (item.shopItemEffect == ShopItemEffect.coinMultiplier) {
        coinMultiplier += item.effectValue * item.level;
      }
    }
    return output * coinMultiplier;
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _generatorTimer?.cancel();
    super.dispose();
  }
}
