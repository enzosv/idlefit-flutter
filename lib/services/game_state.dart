import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:idlefit/models/achievement.dart';
import 'package:idlefit/models/achievement_repo.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/models/shop_items_repo.dart';
import 'package:idlefit/models/currency_repo.dart';
import 'package:idlefit/util.dart';
import 'package:objectbox/objectbox.dart';
import 'storage_service.dart';
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

  // Background state tracking
  double _backgroundCoins = 0;
  double _backgroundEnergy = 0;
  double _backgroundSpace = 0;
  double _backgroundEnergySpent = 0;

  late final Currency coins;
  late final Currency gems;
  late final Currency energy;
  late final Currency space;

  int lastGenerated = 0;
  int doubleCoinExpiry = 0;
  double offlineCoinMultiplier = 0.5;

  // Generators and shop items
  List<CoinGenerator> coinGenerators = [];
  List<ShopItem> shopItems = [];

  // For saving/loading
  late StorageService _storageService;
  late CurrencyRepo _currencyRepo;
  late CoinGeneratorRepo _generatorRepo;
  late ShopItemsRepo _shopItemRepo;
  late DailyQuestRepo _dailyQuestRepo;
  late AchievementRepo _achievementRepo;
  Timer? _autoSaveTimer;
  Timer? _generatorTimer;

  Future<void> initialize(
    StorageService storageService,
    Store objectBoxService,
  ) async {
    _storageService = storageService;

    // Initialize repositories
    _currencyRepo = CurrencyRepo(box: objectBoxService.box<Currency>());
    _generatorRepo = CoinGeneratorRepo(
      box: objectBoxService.box<CoinGenerator>(),
    );
    _shopItemRepo = ShopItemsRepo(box: objectBoxService.box<ShopItem>());
    _dailyQuestRepo = DailyQuestRepo(box: objectBoxService.box<DailyQuest>());
    _achievementRepo = AchievementRepo(
      box: objectBoxService.box<Achievement>(),
    );

    final achievements = await _achievementRepo.loadNewAchievements();
    print("loaded ${achievements.length} achievements");
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
    _backgroundCoins = coins.count;

    // Try to load saved state
    final savedState = await _storageService.loadGameState();
    if (savedState != null) {
      _loadFromSavedState(savedState);
    }
    // Start timers
    _startAutoSave();
    _startGenerators();
  }

  void _loadFromSavedState(Map<String, dynamic> savedState) {
    lastGenerated = savedState['lastGenerated'] ?? 0;
    offlineCoinMultiplier = savedState['offlineCoinMultiplier'] ?? 0.5;
    doubleCoinExpiry = savedState['doubleCoinExpiry'] ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'lastGenerated': lastGenerated,
      'offlineCoinMultiplier': offlineCoinMultiplier,
      'doubleCoinExpiry': doubleCoinExpiry,
    };
  }

  void save() {
    _storageService.saveGameState(toJson());
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
    _backgroundEnergySpent = dif.toDouble();
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
    final realDif = lastGenerated - now;
    final availableDif = validTimeSinceLastGenerate(now, lastGenerated);
    final usesEnergy = realDif > _inactiveThreshold;

    double coinsGenerated = passiveOutput;
    if (usesEnergy) {
      // reduce speed of coin generation in background
      coinsGenerated *= offlineCoinMultiplier;
    }
    coinsGenerated *= (availableDif / _tickTime);

    if (coinsGenerated > 0) {
      coins.earn(coinsGenerated);
      _progressTowards(QuestAction.collect, QuestUnit.coins, coinsGenerated);
      notifyListeners();
    }

    lastGenerated = now;
  }

  void convertHealthStats(double steps, calories, exerciseMinutes) {
    // Calculate health multiplier from upgrades
    double healthMultiplier = 1.0;
    for (final item in shopItems) {
      if (item.shopItemEffect == ShopItemEffect.healthMultiplier) {
        healthMultiplier += item.effectValue * item.level;
      }
    }

    _backgroundEnergy = energy.earn(
      calories * healthMultiplier * _calorieToEnergyMultiplier,
    );
    print("new energy $_backgroundEnergy");
    gems.earn(
      exerciseMinutes * healthMultiplier / 2,
    ); // 2 exercise minutes = 1 gem
    _backgroundSpace = space.earn(steps);

    _progressTowards(QuestAction.walk, QuestUnit.steps, steps);
    _progressTowards(QuestAction.burn, QuestUnit.calories, calories);
    save();
    notifyListeners();
  }

  void _progressTowards(QuestAction action, QuestUnit unit, double progress) {
    _achievementRepo.progressTowards(action, unit, progress);
    _dailyQuestRepo.progressTowards(action, unit, progress);
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
    _progressTowards(QuestAction.spend, QuestUnit.coins, generator.cost);
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
        offlineCoinMultiplier += item.effectValue;
      case ShopItemEffect.coinCapacity:
        coins.maxMultiplier += item.effectValue;
      default:
        break;
    }
    _shopItemRepo.saveShopItem(item);
    _progressTowards(
      QuestAction.spend,
      QuestUnit.space,
      item.currentCost.toDouble(),
    );
    save();
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
    _progressTowards(
      QuestAction.spend,
      QuestUnit.space,
      generator.upgradeUnlockCost,
    );
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
    _progressTowards(QuestAction.spend, QuestUnit.coins, generator.upgradeCost);
    save();
    notifyListeners();
    return true;
  }

  void saveBackgroundState() {
    _backgroundCoins = coins.count;
    _backgroundEnergySpent = 0;
    _backgroundEnergy = 0;
    _backgroundSpace = 0;

    // Schedule notification for when coins will reach capacity
    _scheduleCoinCapacityNotification();
  }

  void _scheduleCoinCapacityNotification() {
    if (coins.count >= coins.max) return;

    final coinsToFill = coins.max - coins.count;
    final effectiveOutput = passiveOutput * offlineCoinMultiplier;
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
    //TODO: reset background state
    return {
      'coins': coins.count - _backgroundCoins,
      'energy_earned': _backgroundEnergy,
      'space': _backgroundSpace,
      'energy_spent': _backgroundEnergySpent,
    };
  }

  double get passiveOutput {
    double output = coinGenerators.fold(
      0,
      (sum, generator) => sum + generator.output,
    );
    double coinMultiplier = 1.0;
    if (doubleCoinExpiry >= DateTime.now().millisecondsSinceEpoch) {
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
