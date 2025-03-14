import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:idlefit/constants.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/models/shop_items_repo.dart';
import 'package:idlefit/models/currency_repo.dart';
import 'package:idlefit/services/background_activity.dart';
import 'package:idlefit/services/storage_service.dart';
import 'package:objectbox/objectbox.dart';
import '../models/shop_items.dart';
import 'package:flutter/foundation.dart';

@immutable
class GameState {
  // Game state
  final bool _isPaused;
  final int _lastGenerated;
  final int _doubleCoinExpiry;
  final double _offlineCoinMultiplier;

  // Currencies
  final Currency _gems;
  final Currency _energy;
  final Currency _space;

  // Generators and shop items
  final List<CoinGenerator> _coinGenerators;
  final List<ShopItem> _shopItems;

  // Services
  final BackgroundActivity _backgroundActivity;
  final StorageService storageService;
  final CurrencyRepo _currencyRepo;
  final CoinGeneratorRepo _generatorRepo;
  final ShopItemsRepo _shopItemRepo;
  final DailyQuestRepo _dailyQuestRepo;

  GameState({
    required bool isPaused,
    required Currency gems,
    required Currency energy,
    required Currency space,
    required int lastGenerated,
    required int doubleCoinExpiry,
    required double offlineCoinMultiplier,
    required List<CoinGenerator> coinGenerators,
    required List<ShopItem> shopItems,
    required this.storageService,
    required CurrencyRepo currencyRepo,
    required CoinGeneratorRepo generatorRepo,
    required ShopItemsRepo shopItemRepo,
    required DailyQuestRepo dailyQuestRepo,
    BackgroundActivity? backgroundActivity,
  }) : _isPaused = isPaused,
       _gems = gems,
       _energy = energy,
       _space = space,
       _lastGenerated = lastGenerated,
       _doubleCoinExpiry = doubleCoinExpiry,
       _offlineCoinMultiplier = offlineCoinMultiplier,
       _coinGenerators = List.unmodifiable(coinGenerators), // Prevents mutation
       _shopItems = List.unmodifiable(shopItems),
       _currencyRepo = currencyRepo,
       _generatorRepo = generatorRepo,
       _shopItemRepo = shopItemRepo,
       _dailyQuestRepo = dailyQuestRepo,
       _backgroundActivity = backgroundActivity ?? BackgroundActivity();

  /// **Public Getters (Encapsulation)**
  bool get isPaused => _isPaused;
  Currency get gems => _gems;
  Currency get energy => _energy;
  Currency get space => _space;
  int get lastGenerated => _lastGenerated;
  int get doubleCoinExpiry => _doubleCoinExpiry;
  double get offlineCoinMultiplier => _offlineCoinMultiplier;
  List<CoinGenerator> get coinGenerators =>
      UnmodifiableListView(_coinGenerators);
  List<ShopItem> get shopItems => UnmodifiableListView(_shopItems);
  BackgroundActivity get backgroundActivity => _backgroundActivity;

  /// **Repositories (Encapsulation)**
  CurrencyRepo get currencyRepo => _currencyRepo;
  CoinGeneratorRepo get generatorRepo => _generatorRepo;
  ShopItemsRepo get shopItemRepo => _shopItemRepo;
  DailyQuestRepo get dailyQuestRepo => _dailyQuestRepo;

  /// **CopyWith (Immutable Updates)**
  GameState copyWith({
    bool? isPaused,
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
      isPaused: isPaused ?? _isPaused,
      gems: gems ?? _gems,
      energy: energy ?? _energy,
      space: space ?? _space,
      lastGenerated: lastGenerated ?? _lastGenerated,
      doubleCoinExpiry: doubleCoinExpiry ?? _doubleCoinExpiry,
      offlineCoinMultiplier: offlineCoinMultiplier ?? _offlineCoinMultiplier,
      coinGenerators: coinGenerators ?? _coinGenerators,
      shopItems: shopItems ?? _shopItems,
      backgroundActivity: backgroundActivity ?? _backgroundActivity,
      storageService: storageService,
      currencyRepo: _currencyRepo,
      generatorRepo: _generatorRepo,
      shopItemRepo: _shopItemRepo,
      dailyQuestRepo: _dailyQuestRepo,
    );
  }

  /// **Initialize Game (Persistence)**
  Future<void> initialize(Store objectBoxService) async {
    _currencyRepo.ensureDefaultCurrencies();
    _currencyRepo.loadCurrencies();
  }

  /// **Convert to JSON (Persistence)**
  Map<String, dynamic> toJson() {
    return {
      'lastGenerated': _lastGenerated,
      'offlineCoinMultiplier': _offlineCoinMultiplier,
      'doubleCoinExpiry': _doubleCoinExpiry,
    };
  }

  /// **Calculate Passive Output**
  double get passiveOutput {
    double output = _coinGenerators.fold(
      0,
      (sum, generator) => sum + generator.output,
    );
    double coinMultiplier = 1.0;
    if (_doubleCoinExpiry >= DateTime.now().millisecondsSinceEpoch) {
      // TODO: what if doubler is active for part of the time?
      coinMultiplier += 1;
    }

    for (final item in _shopItems) {
      if (item.shopItemEffect == ShopItemEffect.coinMultiplier) {
        coinMultiplier += item.effectValue * item.level;
      }
    }

    return output * coinMultiplier;
  }

  /// **Calculate Valid Time Since Last Generate**
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
    return min(dif, _energy.count.round());
  }
}
