import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/shop_items_repo.dart';
import 'package:idlefit/models/currency_repo.dart';
import 'package:idlefit/util.dart';
import 'package:objectbox/objectbox.dart';
import 'storage_service.dart';
import '../models/shop_items.dart';
import 'dart:math';

class GameState with ChangeNotifier {
  static const _tickTime = 1000; // miliseconds
  static const _inactiveThreshold = 30000; // 30 seconds in milliseocnds
  static const _calorieToEnergyMultiplier =
      72000.0; // 1 calorie = 72 seconds of idle fuel

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
  int lastHealthSync = 0;
  int startHealthSync = 0;
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

    if (startHealthSync == 0) {
      final now = DateTime.now();
      startHealthSync =
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    }

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
    _backgroundEnergy = energy.count;
    _backgroundSpace = space.count;

    print("loaded ${coins.max}");

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
    lastHealthSync = savedState['lastHealthSync'] ?? 0;
    startHealthSync = savedState['startHealthSync'] ?? 0;
    offlineCoinMultiplier = savedState['offlineCoinMultiplier'] ?? 0.5;
    doubleCoinExpiry = savedState['doubleCoinExpiry'] ?? 0;
    if (startHealthSync == 0) {
      final now = DateTime.now();
      startHealthSync =
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'lastGenerated': lastGenerated,
      'lastHealthSync': lastHealthSync,
      'startHealthSync': startHealthSync,
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
    if (doubleCoinExpiry > lastGenerated && now >= doubleCoinExpiry) {
      now = doubleCoinExpiry;
      final doublerIndex = shopItems.indexWhere((item) => item.id == 4);
      final doubler = shopItems[doublerIndex];
      doubler.level = 0;
      _shopItemRepo.box.put(doubler);
      shopItems[doublerIndex] = doubler;
    }
    final realDif = lastGenerated - now;
    final availableDif = validTimeSinceLastGenerate(now, lastGenerated);
    final usesEnergy = realDif > _inactiveThreshold;
    double coinsGenerated = 0;

    // Calculate coin multiplier from upgrades
    double coinMultiplier = 1.0;
    if (doubleCoinExpiry >= now) {
      coinMultiplier += 1;
    }
    for (final item in shopItems) {
      if (item.shopItemEffect == ShopItemEffect.coinMultiplier) {
        coinMultiplier += item.effectValue * item.level;
      }
    }

    if (usesEnergy) {
      // reduce speed of coin generation in background
      coinMultiplier *= offlineCoinMultiplier;
    }
    // Process each generator
    for (final generator in coinGenerators) {
      coinsGenerated += (availableDif / _tickTime * generator.output);
    }

    // print(coinsGenerated);

    if (coinsGenerated > 0) {
      // addCoins(coinsGenerated);
      coins.earn(coinsGenerated * coinMultiplier, usesEnergy);
      notifyListeners();
    }

    lastGenerated = now;
  }

  void convertHealthStats(double steps, calories, exerciseMinutes) {
    // Calculate health multiplier from upgrades
    double healthMultiplier = 1.0;
    for (final item in shopItems) {
      if (item.effect == ShopItemEffect.healthMultiplier) {
        healthMultiplier += item.effectValue * item.level;
      }
    }

    energy.earn(calories * healthMultiplier * _calorieToEnergyMultiplier);
    gems.earn(
      exerciseMinutes * healthMultiplier / 2,
    ); // 2 exercise minutes = 1 gem
    space.earn(steps);
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
        // raise energy limit by 1hr every 3
        // TODO: limit to 24hrs
        if (energy.baseMax < 86400000) {
          energy.baseMax += 3600000;
        }
      }
      // TODO: raise space limit
    }
    generator.count++;

    _generatorRepo.saveCoinGenerator(generator);
    save();
    notifyListeners();
    return true;
  }

  bool upgradeShopItem(ShopItem item) {
    if (item.level >= item.maxLevel) return false;

    if (!space.spend(item.currentCost.toDouble())) {
      return false;
    }
    if (item.id == 4) {
      // TODO: watch ad
      // if ad does not finish, return
      doubleCoinExpiry =
          DateTime.now().add(Duration(minutes: 1)).millisecondsSinceEpoch;
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
    _backgroundCoins = coins.count;
    _backgroundEnergy = energy.count;
    _backgroundSpace = space.count;
    _backgroundEnergySpent = 0;
  }

  Map<String, double> getBackgroundState() {
    return {
      'coins': _backgroundCoins,
      'energy_earned': _backgroundEnergy,
      'space': _backgroundSpace,
      'energy_spent': _backgroundEnergySpent,
    };
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _generatorTimer?.cancel();
    super.dispose();
  }
}
