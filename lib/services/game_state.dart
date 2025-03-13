import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/models/time_based_stats.dart';
import 'package:idlefit/repositories/time_based_stats_repo.dart';
import 'package:idlefit/repositories/shop_items_repo.dart';
import 'package:idlefit/repositories/currency_repo.dart';
import 'package:idlefit/services/generator_service.dart';
import 'package:idlefit/services/currency_service.dart';
import 'package:idlefit/services/stats_service.dart';
import 'package:idlefit/services/notification_service.dart';
import 'package:idlefit/util.dart';
import 'package:objectbox/objectbox.dart';
import 'storage_service.dart';
import '../models/shop_items.dart';
import 'dart:math';

class GameState with ChangeNotifier {
  static const _tickTime = 1000; // milliseconds
  static const _inactiveThreshold = 30000; // 30 seconds in milliseconds
  static const _notificationId = 1;

  bool isPaused = true;

  // Services
  late final CurrencyService _currencyService;
  late final GeneratorService _generatorService;
  late final StatsService _statsService;
  late final StorageService _storageService;

  // Background state tracking
  double _backgroundCoins = 0;
  double _backgroundEnergy = 0;
  double _backgroundSpace = 0;
  double _backgroundEnergySpent = 0;

  // Game state
  int lastGenerated = 0;
  int doubleCoinExpiry = 0;
  double offlineCoinMultiplier = 0.5;

  Timer? _autoSaveTimer;
  Timer? _generatorTimer;

  // Getters for easy access to currencies
  Currency get coins => _currencyService.coins;
  Currency get gems => _currencyService.gems;
  Currency get energy => _currencyService.energy;
  Currency get space => _currencyService.space;

  // Getters for generators and shop items
  List<CoinGenerator> get coinGenerators => _generatorService.coinGenerators;
  List<ShopItem> get shopItems => _generatorService.shopItems;

  Future<void> initialize(
    StorageService storageService,
    Store objectBoxService,
  ) async {
    _storageService = storageService;

    // Initialize services
    _currencyService = CurrencyService(
      currencyRepo: CurrencyRepo(box: objectBoxService.box<Currency>()),
    );

    _generatorService = GeneratorService(
      generatorRepo: CoinGeneratorRepo(
        box: objectBoxService.box<CoinGenerator>(),
      ),
      shopItemRepo: ShopItemsRepo(box: objectBoxService.box<ShopItem>()),
    );

    _statsService = StatsService(
      dailyQuestRepo: DailyQuestRepo(box: objectBoxService.box<DailyQuest>()),
      timeBasedStatsRepo: TimeBasedStatsRepo(
        box: objectBoxService.box<TimeBasedStats>(),
      ),
    );

    // Load data
    await _currencyService.initialize();
    await _generatorService.initialize();

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
    _currencyService.saveCurrencies();
    // Not saving generators and shop items. Only changes on buy anyway
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
    // Track energy spent
    _backgroundEnergySpent = dif.toDouble();
    _currencyService.spendEnergy(dif.toDouble());
    print("spent energy ${durationNotation(dif.toDouble())}");
    return dif;
  }

  // The main run loop
  void _processGenerators() {
    if (isPaused) {
      return;
    }

    int now = DateTime.now().millisecondsSinceEpoch;
    final realDif = now - lastGenerated;
    final availableDif = validTimeSinceLastGenerate(now, lastGenerated);
    final usesEnergy = realDif > _inactiveThreshold;

    double coinsGenerated = passiveOutput;
    if (usesEnergy) {
      // reduce speed of coin generation in background
      coinsGenerated *= offlineCoinMultiplier;
    }
    coinsGenerated *= (availableDif / _tickTime);

    if (coinsGenerated > 0) {
      _currencyService.earnCoins(coinsGenerated);
      _statsService.trackPassiveCoinsEarned(coinsGenerated);
      notifyListeners();
    }

    lastGenerated = now;
  }

  void convertHealthStats(
    double steps,
    double calories,
    double exerciseMinutes,
  ) {
    // Calculate health multiplier from upgrades
    double healthMultiplier = _generatorService.getHealthMultiplier();

    // Convert health metrics to in-game currencies
    _backgroundEnergy = _currencyService.convertCaloriesToEnergy(
      calories * healthMultiplier,
    );

    _currencyService.earnGems(
      exerciseMinutes * healthMultiplier / 2,
    ); // 2 exercise minutes = 1 gem

    _backgroundSpace = _currencyService.earnSpace(steps);

    // Track stats and quests
    _statsService.trackHealthMetrics(steps, calories, exerciseMinutes);

    save();
    notifyListeners();
  }

  bool buyCoinGenerator(CoinGenerator generator) {
    if (!_currencyService.canSpendCoins(generator.cost)) {
      return false;
    }

    _currencyService.spendCoins(generator.cost);

    if (generator.count == 0) {
      // Update currency limits based on generator tier
      _updateCurrencyLimitsForNewGenerator(generator);
    }

    _generatorService.incrementGeneratorCount(generator);
    _statsService.trackGeneratorPurchase(generator.tier);

    save();
    notifyListeners();
    return true;
  }

  void _updateCurrencyLimitsForNewGenerator(CoinGenerator generator) {
    // 200*pow(10, generator.tier-1) or next tier cost * 1.8
    final next = coinGenerators[generator.tier].cost;
    final newCoinMax = max(
      next,
      (200 * pow(10, generator.tier - 1).toDouble()),
    );

    _currencyService.updateCoinMax(newCoinMax);

    if (generator.tier % 10 == 0) {
      // Raise gem limit every 10
      _currencyService.increaseGemMax(10);
    }

    if (generator.tier % 5 == 0) {
      // Raise energy limit by 1hr every 5, limit to 24hrs
      _currencyService.increaseEnergyMaxIfBelowLimit();
    }
  }

  bool upgradeShopItem(ShopItem item) {
    if (item.id == 4 || item.level >= item.maxLevel) {
      return false;
    }

    if (!_currencyService.canSpendSpace(item.currentCost.toDouble())) {
      return false;
    }

    _currencyService.spendSpace(item.currentCost.toDouble());

    // Apply the upgrade effect
    _generatorService.upgradeShopItem(item);

    // Update multipliers based on shop item effect
    _updateMultipliersForShopItemUpgrade(item);

    _statsService.trackShopItemUpgrade(item.id);

    save();
    notifyListeners();
    return true;
  }

  void _updateMultipliersForShopItemUpgrade(ShopItem item) {
    switch (item.shopItemEffect) {
      case ShopItemEffect.spaceCapacity:
        _currencyService.increaseSpaceMaxMultiplier(item.effectValue);
        break;
      case ShopItemEffect.energyCapacity:
        _currencyService.increaseEnergyMaxMultiplier(item.effectValue);
        break;
      case ShopItemEffect.offlineCoinMultiplier:
        offlineCoinMultiplier += item.effectValue;
        break;
      case ShopItemEffect.coinCapacity:
        _currencyService.increaseCoinMaxMultiplier(item.effectValue);
        break;
      default:
        break;
    }
  }

  bool unlockGenerator(CoinGenerator generator) {
    if (generator.count < 10 || generator.isUnlocked) {
      return false;
    }

    if (!_currencyService.canSpendSpace(generator.upgradeUnlockCost)) {
      return false;
    }

    _currencyService.spendSpace(generator.upgradeUnlockCost);
    _generatorService.unlockGenerator(generator);
    _statsService.trackGeneratorUnlock(generator.tier);

    save();
    notifyListeners();
    return true;
  }

  bool upgradeGenerator(CoinGenerator generator) {
    if (generator.count < 10 || !generator.isUnlocked) {
      return false;
    }

    if (!_currencyService.canSpendCoins(generator.upgradeCost)) {
      return false;
    }

    _currencyService.spendCoins(generator.upgradeCost);
    _generatorService.upgradeGenerator(generator);
    _statsService.trackGeneratorUpgrade(generator.tier);

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
    return {
      'coins': coins.count - _backgroundCoins,
      'energy_earned': _backgroundEnergy,
      'space': _backgroundSpace,
      'energy_spent': _backgroundEnergySpent,
    };
  }

  double get passiveOutput {
    double output = _generatorService.getTotalPassiveOutput();
    double coinMultiplier = 1.0;

    if (doubleCoinExpiry >= DateTime.now().millisecondsSinceEpoch) {
      coinMultiplier += 1;
    }

    coinMultiplier += _generatorService.getCoinMultiplierFromShopItems();

    return output * coinMultiplier;
  }

  void trackManualGeneratorClick(int generatorTier) {
    _statsService.trackManualGeneratorClick(generatorTier);
  }

  void trackAdView() {
    _statsService.trackAdView();
  }

  // Get all game statistics
  Map<String, dynamic> getGameStats() {
    return _statsService.getStats();
  }

  // Get daily statistics
  Map<String, dynamic> getDailyStats() {
    return _statsService.getDailyStats();
  }

  // Get weekly statistics
  Map<String, dynamic> getWeeklyStats() {
    return _statsService.getWeeklyStats();
  }

  // Get monthly statistics
  Map<String, dynamic> getMonthlyStats() {
    return _statsService.getMonthlyStats();
  }

  // Get stats for the last N days
  List<Map<String, dynamic>> getStatsForLastNDays(int days) {
    return _statsService.getStatsForLastNDays(days);
  }

  // Get stats for the last N weeks
  List<Map<String, dynamic>> getStatsForLastNWeeks(int weeks) {
    return _statsService.getStatsForLastNWeeks(weeks);
  }

  // Get stats for the last N months
  List<Map<String, dynamic>> getStatsForLastNMonths(int months) {
    return _statsService.getStatsForLastNMonths(months);
  }

  // Get stats for a specific time range
  Map<String, dynamic> getStatsForTimeRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _statsService.getStatsForTimeRange(startDate, endDate);
  }

  // Reset all game statistics
  void resetStats() {
    _statsService.resetStats();
    notifyListeners();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _generatorTimer?.cancel();
    super.dispose();
  }
}
