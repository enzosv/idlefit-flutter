import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:idlefit/game/coin_generator.dart';
import 'package:idlefit/game/currency.dart';
import 'package:objectbox/objectbox.dart';
import '../services/storage_service.dart';
import 'shop_items.dart';
import 'dart:math';

class GameState with ChangeNotifier {
  final tickTime = 1000; // miliseconds
  bool isPaused = true;

  final Currency coins = Currency(id: CurrencyType.coin.index, count: 10);
  final Currency gem = Currency(id: CurrencyType.gem.index);
  final Currency energy = Currency(id: CurrencyType.energy.index);
  final Currency spaces = Currency(id: CurrencyType.space.index);
  // Currency
  int gems = 0;
  int space = 0;
  int lastGenerated = 0;
  int lastHealthSync = 0;

  // Health Metrics
  int totalSteps = 0;
  double totalCaloriesBurned = 0;
  int totalExerciseMinutes = 0;

  // Game statistics
  int totalGemsEarned = 0;
  int totalGemsSpent = 0;
  int totalSpaceEarned = 0;
  int totalSpaceSpent = 0;

  // Generators and shop items
  List<CoinGenerator> coinGenerators = [];
  List<ShopItem> shopItems = [];

  // For saving/loading
  late StorageService _storageService;
  late Store _objectBoxService;
  Timer? _autoSaveTimer;
  Timer? _generatorTimer;

  Future<void> initialize(
    StorageService storageService,
    Store objectBoxServivce,
  ) async {
    _storageService = storageService;
    _objectBoxService = objectBoxServivce;

    // Initialize default generators
    coinGenerators = await parseCoinGenerators(
      'assets/coin_generators.json',
      objectBoxServivce,
    );
    final currencyBox = objectBoxServivce.box<Currency>();
    final currencies = currencyBox.getAll().toList();
    for (final currency in currencies) {
      switch (currency.type) {
        case CurrencyType.coin:
          coins.mirror(currency);
          continue;
        case CurrencyType.energy:
          energy.mirror(currency);
          continue;
        case CurrencyType.gem:
          gem.mirror(currency);
          continue;
        case CurrencyType.space:
          spaces.mirror(currency);
          continue;
        default:
          continue;
      }
    }
    // Initialize shop items
    shopItems = [
      ShopItem(
        id: 'coin_boost',
        name: 'Coin Boost',
        description: 'Increases all coin generation by 10%',
        cost: 10,
        effect: ShopItemEffect.coinMultiplier,
        effectValue: 0.1,
        maxLevel: 10,
        level: 0,
      ),
      ShopItem(
        id: 'health_boost',
        name: 'Health Converter',
        description: 'Get more coins from health activities',
        cost: 15,
        effect: ShopItemEffect.healthMultiplier,
        effectValue: 0.2,
        maxLevel: 5,
        level: 0,
      ),
      ShopItem(
        id: 'energy_capacity',
        name: 'Energy Capacity',
        description: 'Increases max energy by 50',
        cost: 20,
        effect: ShopItemEffect.energyCapacity,
        effectValue: 50,
        maxLevel: 10,
        level: 0,
      ),
    ];

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
    // coins = savedState['coins'] ?? 0;
    gems = savedState['gems'] ?? 0;
    space = savedState['space'] ?? 0;
    lastGenerated = savedState['lastGenerated'] ?? 0;
    lastHealthSync = savedState['lastHealthSync'] ?? 0;

    totalSteps = savedState['totalSteps'] ?? 0;
    totalCaloriesBurned = savedState['totalCaloriesBurned'] ?? 0.0;
    totalExerciseMinutes = savedState['totalExerciseMinutes'] ?? 0;

    // totalCoinsEarned = savedState['totalCoinsEarned'] ?? 0;
    // totalCoinsSpent = savedState['totalCoinsSpent'] ?? 0;
    totalGemsEarned = savedState['totalGemsEarned'] ?? 0;
    totalGemsSpent = savedState['totalGemsSpent'] ?? 0;
    totalSpaceEarned = savedState['totalSpaceEarned'] ?? 0;
    totalSpaceSpent = savedState['totalSpaceSpent'] ?? 0;

    // Load shop items
    if (savedState['shopItems'] != null) {
      final List<dynamic> shopData = savedState['shopItems'];
      for (final itemJson in shopData) {
        final itemId = itemJson['id'];
        final itemIndex = shopItems.indexWhere((s) => s.id == itemId);
        if (itemIndex >= 0) {
          shopItems[itemIndex].level = itemJson['level'] ?? 0;
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'coins': coins,
      'gems': gems,
      'space': space,
      'lastGenerated': lastGenerated,
      'lastHealthSync': lastHealthSync,
      'totalSteps': totalSteps,
      'totalCaloriesBurned': totalCaloriesBurned,
      'totalExerciseMinutes': totalExerciseMinutes,
      'totalGemsEarned': totalGemsEarned,
      'totalGemsSpent': totalGemsSpent,
      'totalSpaceEarned': totalSpaceEarned,
      'totalSpaceSpent': totalSpaceSpent,
      'shopItems': shopItems.map((s) => s.json).toList(),
    };
  }

  void save() {
    _storageService.saveGameState(toJson());
    final currencyBox = _objectBoxService.box<Currency>();
    currencyBox.put(coins);
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      save();
    });
  }

  void _startGenerators() {
    final duration = Duration(milliseconds: tickTime);
    _generatorTimer = Timer.periodic(duration, (_) {
      _processGenerators();
    });
  }

  int validTimeSinceLastGenerate(int now, int previous) {
    if (energy.count <= 0 || previous <= 0) {
      return tickTime;
    }

    int dif = now - tickTime;
    dif = now - previous;
    // if last generated > 30s, consume energy
    if (dif < 30000) {
      // do not consume energy
      return dif;
    }
    dif = min(dif, energy.count.round());
    // smelly to perform modification in get
    energy.spend(dif.toDouble());
    print("spent energy $dif");
    return dif;
  }

  void _processGenerators() {
    if (isPaused) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final dif = validTimeSinceLastGenerate(now, lastGenerated);

    double coinsGenerated = 0;

    // Calculate coin multiplier from upgrades
    double coinMultiplier = 1.0;
    for (final item in shopItems) {
      if (item.effect == ShopItemEffect.coinMultiplier) {
        coinMultiplier += item.effectValue * item.level;
      }
    }
    // Process each generator
    for (final generator in coinGenerators) {
      coinsGenerated += (dif / tickTime * generator.output * coinMultiplier);
    }

    // print(coinsGenerated);

    if (coinsGenerated > 0) {
      // addCoins(coinsGenerated);
      coins.earn(coinsGenerated);
      notifyListeners();
    }

    lastGenerated = now;
  }

  void processHealthData(int steps, double calories, int exerciseMinutes) {
    // Update totals
    totalSteps += steps;
    totalCaloriesBurned += calories;
    totalExerciseMinutes += exerciseMinutes;

    // Calculate health multiplier from upgrades
    double healthMultiplier = 1.0;
    for (final item in shopItems) {
      if (item.effect == ShopItemEffect.healthMultiplier) {
        healthMultiplier += item.effectValue * item.level;
      }
    }

    energy.earn(
      calories * healthMultiplier * 72000,
    ); // 1 calorie = 72 seconds of idle fuel
    addGems(
      (exerciseMinutes * healthMultiplier / 2).round(),
    ); // 2 exercise minutes = 1 gem
    addSpace((steps * healthMultiplier).round());

    // Add energy based on activity

    notifyListeners();
  }

  // void addCoins(double amount) {
  //   coins += amount;
  //   totalCoinsEarned += amount;
  //   notifyListeners();
  // }

  // bool spendCoins(double amount) {
  //   if (coins >= amount) {
  //     coins -= amount;
  //     totalCoinsSpent += amount;
  //     notifyListeners();
  //     return true;
  //   }
  //   return false;
  // }

  void addGems(int amount) {
    gems += amount;
    totalGemsEarned += amount;
    notifyListeners();
  }

  void addSpace(int amount) {
    space += amount;
    totalSpaceEarned += amount;
    notifyListeners();
  }

  bool spendGems(int amount) {
    if (gems >= amount) {
      gems -= amount;
      totalGemsSpent += amount;
      notifyListeners();
      return true;
    }
    return false;
  }

  bool buyCoinGenerator(CoinGenerator generator) {
    if (!coins.spend(generator.cost)) {
      return false;
    }
    generator.count++;
    notifyListeners();
    final currencyBox = _objectBoxService.box<Currency>();
    currencyBox.put(coins);
    _objectBoxService.box<CoinGenerator>().put(generator);
    return true;
  }

  bool upgradeShopItem(ShopItem item) {
    if (item.level >= item.maxLevel) return false;

    final cost = item.currentCost;
    if (spendGems(cost)) {
      item.level++;
      notifyListeners();
      save();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _generatorTimer?.cancel();
    super.dispose();
  }
}
