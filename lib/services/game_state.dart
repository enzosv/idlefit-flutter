import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:idlefit/constants.dart';
import 'package:idlefit/main.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/shop_items_repo.dart';
import 'package:idlefit/models/currency_repo.dart';
import 'package:idlefit/util.dart';
import 'package:objectbox/objectbox.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';
import '../models/shop_items.dart';
import 'dart:math';
import 'notification_service.dart';

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
  // final StorageService storageService;
  final CurrencyRepo currencyRepo;
  final CoinGeneratorRepo generatorRepo;
  final ShopItemsRepo shopItemRepo;
  Timer? _autoSaveTimer;
  Timer? _generatorTimer;

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
    // required StorageService storageService,
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
      // storageService: _storageService,
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

    // Start timers
    _startAutoSave();
    // _startGenerators();
  }

  Map<String, dynamic> toJson() {
    return {
      'lastGenerated': lastGenerated,
      'offlineCoinMultiplier': offlineCoinMultiplier,
      'doubleCoinExpiry': doubleCoinExpiry,
    };
  }

  void save() {
    // _storageService.saveGameState(toJson());
    currencyRepo.saveCurrencies([coins, energy, gems, space]);
    // not saving generators and shopitems. only changes on buy anyway
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      save();
    });
  }

  void saveBackgroundState() {
    backgroundState['coins'] = coins.count;
    backgroundState['energySpent'] = 0;
    backgroundState['energy'] = 0;
    backgroundState['space'] = 0;

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
      id: Constants.notificationId,
      scheduledDate: notificationTime,
      title: 'Coin Capacity Full',
      body:
          'Your coins have reached maximum capacity! Time to upgrade or spend.',
    );
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

  void dispose() {
    _autoSaveTimer?.cancel();
    _generatorTimer?.cancel();
  }
}
