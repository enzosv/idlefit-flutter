import 'dart:async';
import 'dart:math';
import 'package:idlefit/constants.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/shop_items_repo.dart';
import 'package:idlefit/models/currency_repo.dart';
import 'package:idlefit/services/background_activity.dart';
import 'package:idlefit/services/storage_service.dart';
import 'package:objectbox/objectbox.dart';
import '../models/shop_items.dart';

class GameState {
  final bool isPaused;

  final BackgroundActivity backgroundActivity;

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
    BackgroundActivity? backgroundActivity,
  }) : currencyRepo = currencyRepo,
       generatorRepo = generatorRepo,
       shopItemRepo = shopItemRepo,
       backgroundActivity = backgroundActivity ?? BackgroundActivity();

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
    BackgroundActivity? backgroundActivity,
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
      backgroundActivity: backgroundActivity ?? this.backgroundActivity,
      storageService: storageService,
      currencyRepo: currencyRepo,
      generatorRepo: generatorRepo,
      shopItemRepo: shopItemRepo,
    );
  }

  Future<void> initialize(Store objectBoxService) async {
    // Ensure default currencies exist and load them
    currencyRepo.ensureDefaultCurrencies();
    currencyRepo.loadCurrencies();
  }

  Map<String, dynamic> toJson() {
    return {
      'lastGenerated': lastGenerated,
      'offlineCoinMultiplier': offlineCoinMultiplier,
      'doubleCoinExpiry': doubleCoinExpiry,
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

  int calculateValidTimeSinceLastGenerate(int now, int previous) {
    if (previous <= 0) {
      return Constants.tickTime;
    }
    final dif = now - previous;
    if (dif < 0) {
      return Constants.tickTime;
    }

    if (dif < Constants.inactiveThreshold) {
      // even if app became inactive, it wasn't long enough. don't limit to energy
      return dif;
    }

    // limit to energy
    return min(dif, energy.count.round());
  }
}
