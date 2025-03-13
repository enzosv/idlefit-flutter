import 'dart:async';
import 'dart:math';
import 'package:idlefit/constants.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/shop_items_repo.dart';
import 'package:idlefit/models/currency_repo.dart';
import 'package:idlefit/services/storage_service.dart';
import 'package:objectbox/objectbox.dart';
import '../models/shop_items.dart';

class GameState {
  final bool isPaused;

  // Background state tracking
  final Map<String, double> backgroundState;

  final Currency coins;
  final Currency gems;
  final Currency energy;
  final Currency space;

  final int lastGenerated;
  final int doubleCoinExpiry;
  final double offlineCoinMultiplier;

  // Generators and shop items
  final List<CoinGenerator> coinGenerators;
  final List<ShopItem> shopItems;

  // For saving/loading
  final StorageService storageService;
  final CurrencyRepo currencyRepo;
  final CoinGeneratorRepo generatorRepo;
  final ShopItemsRepo shopItemRepo;

  GameState({
    required this.isPaused,
    required this.coins,
    required this.gems,
    required this.energy,
    required this.space,
    required this.lastGenerated,
    required this.doubleCoinExpiry,
    required this.offlineCoinMultiplier,
    required this.coinGenerators,
    required this.shopItems,
    required this.storageService,
    required CurrencyRepo currencyRepo,
    required CoinGeneratorRepo generatorRepo,
    required ShopItemsRepo shopItemRepo,
    Map<String, double>? backgroundState,
  }) : currencyRepo = currencyRepo,
       generatorRepo = generatorRepo,
       shopItemRepo = shopItemRepo,
       backgroundState =
           backgroundState ??
           {'coins': 0, 'energy': 0, 'space': 0, 'energySpent': 0};

  GameState copyWith({
    bool? isPaused,
    Currency? coins,
    Currency? gems,
    Currency? energy,
    Currency? space,
    int? lastGenerated,
    int? doubleCoinExpiry,
    double? offlineCoinMultiplier,
    List<CoinGenerator>? coinGenerators,
    List<ShopItem>? shopItems,
    Map<String, double>? backgroundState,
  }) {
    return GameState(
      isPaused: isPaused ?? this.isPaused,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      energy: energy ?? this.energy,
      space: space ?? this.space,
      lastGenerated: lastGenerated ?? this.lastGenerated,
      doubleCoinExpiry: doubleCoinExpiry ?? this.doubleCoinExpiry,
      offlineCoinMultiplier:
          offlineCoinMultiplier ?? this.offlineCoinMultiplier,
      coinGenerators: coinGenerators ?? this.coinGenerators,
      shopItems: shopItems ?? this.shopItems,
      backgroundState: backgroundState ?? this.backgroundState,
      storageService: storageService,
      currencyRepo: currencyRepo,
      generatorRepo: generatorRepo,
      shopItemRepo: shopItemRepo,
    );
  }

  Future<void> initialize(Store objectBoxService) async {
    // Ensure default currencies exist and load them
    currencyRepo.ensureDefaultCurrencies();
    final currencies = currencyRepo.loadCurrencies();
    final coins = currencies[CurrencyType.coin]!;
    backgroundState['coins'] = coins.count;
  }

  Map<String, dynamic> toJson() {
    return {
      'lastGenerated': lastGenerated,
      'offlineCoinMultiplier': offlineCoinMultiplier,
      'doubleCoinExpiry': doubleCoinExpiry,
    };
  }

  void save() {
    storageService.saveGameState(toJson());
    currencyRepo.saveCurrencies([coins, energy, gems, space]);
    // not saving generators and shopitems. only changes on buy anyway
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

  int calculateValidTimeSinceLastGenerate(int now, int previous) {
    if (energy.count <= 0 || previous <= 0) {
      return Constants.tickTime;
    }

    int dif = now - previous;
    if (dif < Constants.inactiveThreshold) {
      return dif;
    }

    return min(dif, energy.count.round());
  }

  Map<String, double> getBackgroundStateSnapshot() {
    return {'coins': coins.count, 'energy': 0, 'space': 0, 'energySpent': 0};
  }

  Map<String, double> getBackgroundDifferences() {
    return {
      'coins': coins.count - (backgroundState['coins'] ?? 0),
      'energy_earned': backgroundState['energy'] ?? 0,
      'space': backgroundState['space'] ?? 0,
      'energy_spent': backgroundState['energySpent'] ?? 0,
    };
  }
}
