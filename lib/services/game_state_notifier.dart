import 'dart:async';
import 'package:idlefit/constants.dart';
import 'package:idlefit/main.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/models/shop_items_repo.dart';
import 'package:idlefit/models/currency_repo.dart';
import 'package:idlefit/providers/coin_provider.dart';
import 'package:idlefit/providers/generator_provider.dart';
import 'package:idlefit/services/background_activity.dart';
import 'package:idlefit/services/game_state.dart';
import 'package:objectbox/objectbox.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';
import '../models/shop_items.dart';
import 'dart:math';
import 'notification_service.dart';

class GameStateNotifier extends StateNotifier<GameState> {
  final Ref ref;
  Timer? _generatorTimer;

  GameStateNotifier(this.ref, super.state) {
    _startGenerators();
  }

  Future<void> initialize(
    StorageService storageService,
    Store objectBoxService,
  ) async {
    // Load data from repositories
    ref.read(generatorProvider.notifier).initialize();
    final shopItems = await state.shopItemRepo.parseShopItems(
      'assets/shop_items.json',
    );

    // Ensure default currencies exist and load them
    state.currencyRepo.ensureDefaultCurrencies();
    final currencies = state.currencyRepo.loadCurrencies();
    ref.read(coinProvider.notifier).initialize(currencies[CurrencyType.coin]!);
    ref.read(gemProvider.notifier).initialize(currencies[CurrencyType.gem]!);
    ref
        .read(energyProvider.notifier)
        .initialize(currencies[CurrencyType.energy]!);
    ref
        .read(spaceProvider.notifier)
        .initialize(currencies[CurrencyType.space]!);

    // Try to load saved state
    final savedState = await storageService.loadGameState();

    state = state.copyWith(
      shopItems: shopItems,
      lastGenerated: savedState?['lastGenerated'] ?? 0,
      offlineCoinMultiplier: savedState?['offlineCoinMultiplier'] ?? 0.5,
      doubleCoinExpiry: savedState?['doubleCoinExpiry'] ?? 0,
      backgroundActivity: BackgroundActivity(),
    );
  }

  void setIsPaused(bool isPaused) {
    state = state.copyWith(isPaused: isPaused);
    // _save();
  }

  void _startGenerators() {
    final duration = Duration(milliseconds: Constants.tickTime);
    _generatorTimer = Timer.periodic(duration, (_) {
      _processGenerators();
    });
  }

  void _save() {
    state.storageService.saveGameState(state.toJson());
    state.currencyRepo.saveCurrencies([
      ref.read(coinProvider),
      ref.read(gemProvider),
      ref.read(energyProvider),
      ref.read(spaceProvider),
    ]);
    // not saving generators and shopitems. only changes on buy anyway
  }

  void _processGenerators() {
    if (state.isPaused) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final realDif = now - state.lastGenerated;
    final dif = calculateValidTimeSinceLastGenerate(now, state.lastGenerated);
    final coinsNotifier = ref.read(coinProvider.notifier);

    // Handle coin generation
    double coinsGenerated = passiveOutput;
    if (coinsGenerated <= 0) {
      // no coins generated, skip
      return;
    }
    coinsGenerated *= (dif / Constants.tickTime);
    if (realDif < Constants.inactiveThreshold) {
      // don't use energy
      // earn coins
      coinsNotifier.earn(coinsGenerated);
      state = state.copyWith(lastGenerated: now);
      _save();
      return;
    }
    // use energy
    // reduce coins generated offline
    coinsGenerated *= state.offlineCoinMultiplier;
    coinsNotifier.earn(coinsGenerated);

    // consume energy
    final energyNotifier = ref.read(energyProvider.notifier);
    energyNotifier.spend(dif.toDouble());
    // track energy spent for popup
    final newBackgroundActivity = state.backgroundActivity.copyWith(
      energySpent: dif.toDouble(),
      coinsEarned: coinsGenerated,
    );

    // update state
    state = state.copyWith(
      backgroundActivity: newBackgroundActivity,
      lastGenerated: now,
    );
    _save();
  }

  void convertHealthStats(
    double steps,
    double calories,
    double exerciseMinutes,
  ) {
    double healthMultiplier = 1.0;
    for (final item in state.shopItems) {
      if (item.shopItemEffect == ShopItemEffect.healthMultiplier) {
        healthMultiplier += item.effectValue * item.level;
      }
    }

    final energyGain =
        calories * healthMultiplier * Constants.calorieToEnergyMultiplier;
    final gemGain = exerciseMinutes * healthMultiplier / 2;

    final newBackgroundActivity = state.backgroundActivity.copyWith(
      energyEarned: energyGain,
      spaceEarned: steps,
    );
    ref.read(energyProvider.notifier).earn(energyGain);
    ref.read(gemProvider.notifier).earn(gemGain);
    ref.read(spaceProvider.notifier).earn(steps);

    state = state.copyWith(backgroundActivity: newBackgroundActivity);

    _save();
  }

  @override
  void dispose() {
    _generatorTimer?.cancel();
    super.dispose();
  }

  void setDoubleCoinExpiry(int expiry) {
    state = state.copyWith(doubleCoinExpiry: expiry);
    _save();
  }

  void scheduleCoinCapacityNotification() {
    final coins = ref.read(coinProvider);
    if (coins.count >= coins.max) return;

    final coinsToFill = coins.max - coins.count;
    final effectiveOutput = passiveOutput * state.offlineCoinMultiplier;
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

  bool upgradeShopItem(ShopItem item) {
    if (item.id == 4 || item.level >= item.maxLevel) return false;

    final spaceNotifier = ref.read(spaceProvider.notifier);

    spaceNotifier.spend(item.currentCost.toDouble());

    item.level++;

    switch (item.shopItemEffect) {
      case ShopItemEffect.spaceCapacity:
        spaceNotifier.updateMaxMultiplier(item.effectValue);
      case ShopItemEffect.energyCapacity:
        ref.read(energyProvider.notifier).updateMaxMultiplier(item.effectValue);
      case ShopItemEffect.offlineCoinMultiplier:
        state = state.copyWith(
          offlineCoinMultiplier: state.offlineCoinMultiplier + item.effectValue,
        );
      case ShopItemEffect.coinCapacity:
        final coinsNotifier = ref.read(coinProvider.notifier);
        coinsNotifier.updateMaxMultiplier(item.effectValue);
      default:
        assert(false, 'unhandled shop item effect ${item.shopItemEffect}');
        break;
    }

    state.shopItemRepo.saveShopItem(item);
    _save();
    return true;
  }

  /// **Calculate Passive Output**
  double get passiveOutput {
    final generators = ref.read(generatorProvider);
    double output = generators.fold(
      0,
      (sum, generator) => sum + generator.output,
    );
    double coinMultiplier = 1.0;
    if (state.doubleCoinExpiry >= DateTime.now().millisecondsSinceEpoch) {
      // TODO: what if doubler is active for part of the time?
      coinMultiplier += 1;
    }

    for (final item in state.shopItems) {
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
    return min(dif, ref.read(energyProvider).count.round());
  }
}

// Create providers
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((
  ref,
) {
  final store =
      ref
          .read(objectBoxProvider)
          .store; // You'll need to properly initialize this
  final storageService = ref.read(storageServiceProvider);
  return GameStateNotifier(
    ref,
    GameState(
      isPaused: true,
      lastGenerated: 0,
      doubleCoinExpiry: 0,
      offlineCoinMultiplier: 0.5,
      shopItems: [],
      storageService: storageService,
      currencyRepo: CurrencyRepo(box: store.box<Currency>()),
      shopItemRepo: ShopItemsRepo(box: store.box<ShopItem>()),
      dailyQuestRepo: DailyQuestRepo(box: store.box<DailyQuest>()),
    ),
  );
});
