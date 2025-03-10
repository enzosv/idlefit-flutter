import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/shop_items_repo.dart';
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

  final Currency coins = Currency(
    id: CurrencyType.coin.index,
    count: 10,
    baseMax: 100,
  );
  final Currency gems = Currency(id: CurrencyType.gem.index);
  final Currency energy = Currency(
    id: CurrencyType.energy.index,
    baseMax: 43200000,
  );
  final Currency space = Currency(id: CurrencyType.space.index);

  int lastGenerated = 0;
  int lastHealthSync = 0;
  int startHealthSync = 0;

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
    Store objectBoxService,
  ) async {
    _storageService = storageService;
    _objectBoxService = objectBoxService;

    if (startHealthSync == 0) {
      final now = DateTime.now();
      startHealthSync =
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    }

    // Initialize default generators
    final coinRepo = CoinGeneratorRepo(
      box: objectBoxService.box<CoinGenerator>(),
    );
    coinGenerators = await coinRepo.parseCoinGenerators(
      'assets/coin_generators.json',
    );
    final shopItemRepo = ShopItemsRepo(box: objectBoxService.box<ShopItem>());
    shopItems = await shopItemRepo.parseShopItems(
      'assets/shop_items.json',
    );
    final currencyBox = objectBoxService.box<Currency>();
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
          gems.mirror(currency);
          continue;
        case CurrencyType.space:
          space.mirror(currency);
          continue;
        default:
          continue;
      }
    }
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
    };
  }

  void save() {
    _storageService.saveGameState(toJson());
    final currencyBox = _objectBoxService.box<Currency>();
    currencyBox.putMany([coins, energy, gems, space]);
        // not saving generators. only changes on buy anyway
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

    int dif = now - _tickTime;
    dif = now - previous;
    // if last generated > 30s, consume energy
    if (dif < _inactiveThreshold) {
      // do not consume energy
      return dif;
    }
    dif = min(dif, energy.count.round());
    // smelly to perform modification in get
    energy.spend(dif.toDouble());
    print("spent energy $dif");
    return dif;
  }

  // the main run loop
  void _processGenerators() {
    if (isPaused) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final realDif = lastGenerated - now;
    final availableDif = validTimeSinceLastGenerate(now, lastGenerated);
    final usesEnergy = realDif > _inactiveThreshold;
    double coinsGenerated = 0;

    // Calculate coin multiplier from upgrades
    double coinMultiplier = 1.0;
    for (final item in shopItems) {
      if (item.effect == ShopItemEffect.coinMultiplier) {
        coinMultiplier += item.effectValue * item.level;
      }
    }

    if (usesEnergy) {
      // reduce speed of coin generation in background
      coinMultiplier /= 2;
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
    space.earn(steps * healthMultiplier);
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
      coins.baseMax = max(
        next * 1.8,
        (200 * pow(10, generator.tier - 1).toDouble()),
      );

    if (generator.tier % 10 == 0) {
      // raise gem limit every 10
        gems.baseMax += 10;
    }
    if (generator.tier % 3 == 0) {
        // raise energy limit by 1hr every 3
        energy.baseMax += 3600000;
    }
    // TODO: raise space limit
    }
    generator.count++;

    _objectBoxService.box<CoinGenerator>().put(generator);
    save();
    notifyListeners();
    return true;
  }

  bool upgradeShopItem(ShopItem item) {
    if (item.level >= item.maxLevel) return false;

    if (!gems.spend(item.currentCost.toDouble())) {
      return false;
    }

    item.level++;
    save();
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _generatorTimer?.cancel();
    super.dispose();
  }
}
