import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/shop_items.dart';
import 'package:idlefit/util.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'coin_generator_provider.dart';
import 'currency_provider.dart';
import 'player_stats_provider.dart';
import 'shop_item_provider.dart';

part 'game_engine_provider.g.dart';

@Riverpod(keepAlive: true)
class GameEngine extends _$GameEngine {
  static const _tickTime = 1000; // milliseconds
  static const _inactiveThreshold = 30000; // 30 seconds in milliseconds
  static const _calorieToEnergyMultiplier =
      72000.0; // 1 calorie = 72 seconds of idle fuel
  static const _notificationId = 1;

  Timer? _generatorTimer;
  bool _isPaused = true;

  @override
  bool build() {
    ref.onDispose(() {
      _stopGeneratorTimer();
    });
    return _isPaused;
  }

  void _stopGeneratorTimer() {
    _generatorTimer?.cancel();
    _generatorTimer = null;
  }

  void setPaused(bool paused) {
    if (paused == _isPaused) return;

    _isPaused = paused;
    state = paused;

    if (paused) {
      _stopGeneratorTimer();
    } else {
      _startGeneratorTimer();
    }
  }

  void _startGeneratorTimer() {
    _stopGeneratorTimer();

    final duration = Duration(milliseconds: _tickTime);
    _generatorTimer = Timer.periodic(duration, (_) {
      _processGenerators();
    });
  }

  void _processGenerators() {
    if (_isPaused) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final playerStats = ref.read(playerStatsNotifierProvider);
    final lastGenerated = playerStats.lastGenerated;

    final realDif = lastGenerated - now;
    final availableDif = _validTimeSinceLastGenerate(now, lastGenerated);
    final usesEnergy = realDif > _inactiveThreshold;

    double coinsGenerated = _calculatePassiveOutput();
    if (usesEnergy) {
      // reduce speed of coin generation in background
      coinsGenerated *= playerStats.offlineCoinMultiplier;
    }
    coinsGenerated *= (availableDif / _tickTime);

    if (coinsGenerated > 0) {
      ref
          .read(currencyNotifierProvider.notifier)
          .earn(CurrencyType.coin, coinsGenerated);
    }

    ref.read(playerStatsNotifierProvider.notifier).updateLastGenerated(now);
  }

  int _validTimeSinceLastGenerate(int now, int previous) {
    final energy = ref.read(currencyNotifierProvider)[CurrencyType.energy];
    if (energy == null || energy.count <= 0 || previous <= 0) {
      return _tickTime;
    }

    int dif = now - previous;
    // if last generated > 30s, consume energy
    if (dif < _inactiveThreshold) {
      // do not consume energy
      return dif;
    }

    dif = min(dif, energy.count.round());
    // Update energy spent in background tracking
    ref
        .read(playerStatsNotifierProvider.notifier)
        .setBackgroundEnergySpent(dif.toDouble());

    // Spend energy
    ref
        .read(currencyNotifierProvider.notifier)
        .spend(CurrencyType.energy, dif.toDouble());

    print("spent energy ${durationNotation(dif.toDouble())}");
    return dif;
  }

  double _calculatePassiveOutput() {
    double output = ref
        .read(coinGeneratorNotifierProvider)
        .when(
          data: (generators) {
            return generators.fold(
              0.0,
              (sum, generator) => sum + generator.output,
            );
          },
          loading: () => 0.0,
          error: (_, __) => 0.0,
        );

    double coinMultiplier = 1.0;

    // Apply double coin expiry if active
    final playerStats = ref.read(playerStatsNotifierProvider);
    if (playerStats.doubleCoinExpiry >= DateTime.now().millisecondsSinceEpoch) {
      coinMultiplier += 1.0;
    }

    // Apply shop item multipliers
    ref
        .read(shopItemNotifierProvider)
        .when(
          data: (items) {
            for (final item in items) {
              if (item.shopItemEffect == ShopItemEffect.coinMultiplier) {
                coinMultiplier += item.effectValue * item.level;
              }
            }
          },
          loading: () {},
          error: (_, __) {},
        );

    return output * coinMultiplier;
  }

  void convertHealthStats(
    double steps,
    double calories,
    double exerciseMinutes,
  ) {
    // Calculate health multiplier from upgrades
    double healthMultiplier = 1.0;

    ref
        .read(shopItemNotifierProvider)
        .when(
          data: (items) {
            for (final item in items) {
              if (item.shopItemEffect == ShopItemEffect.healthMultiplier) {
                healthMultiplier += item.effectValue * item.level;
              }
            }
          },
          loading: () {},
          error: (_, __) {},
        );

    // Apply energy from calories
    final energyEarned = ref
        .read(currencyNotifierProvider.notifier)
        .earn(
          CurrencyType.energy,
          calories * healthMultiplier * _calorieToEnergyMultiplier,
        );

    ref
        .read(playerStatsNotifierProvider.notifier)
        .setBackgroundEnergy(energyEarned);

    // Apply gems from exercise minutes
    ref
        .read(currencyNotifierProvider.notifier)
        .earn(CurrencyType.gem, exerciseMinutes * healthMultiplier / 2);

    // Apply space from steps
    final spaceEarned = ref
        .read(currencyNotifierProvider.notifier)
        .earn(CurrencyType.space, steps);

    ref
        .read(playerStatsNotifierProvider.notifier)
        .setBackgroundSpace(spaceEarned);

    // Save state
    ref.read(currencyNotifierProvider.notifier).saveCurrencies();
    ref.read(playerStatsNotifierProvider.notifier).save();
  }

  void saveBackgroundState() {
    final currencyNotifier = ref.read(currencyNotifierProvider.notifier);
    final currencies = ref.read(currencyNotifierProvider);

    ref
        .read(playerStatsNotifierProvider.notifier)
        .updateBackgroundState(
          currencies[CurrencyType.coin]?.count ?? 0,
          currencies[CurrencyType.energy]?.count ?? 0,
          currencies[CurrencyType.space]?.count ?? 0,
        );

    // Save state
    currencyNotifier.saveCurrencies();
    ref.read(playerStatsNotifierProvider.notifier).save();

    // TODO: Add notification scheduling logic here
  }

  Map<String, double> getBackgroundDifferences() {
    final currencies = ref.read(currencyNotifierProvider);

    return ref
        .read(playerStatsNotifierProvider.notifier)
        .getBackgroundDifferences(
          currencies[CurrencyType.coin]?.count ?? 0,
          currencies[CurrencyType.energy]?.count ?? 0,
          currencies[CurrencyType.space]?.count ?? 0,
        );
  }

  // Game actions
  bool buyCoinGenerator(int tier) {
    // This code will be accessed by widgets
    final generatorsAsyncValue = ref.read(coinGeneratorNotifierProvider);

    return generatorsAsyncValue.when(
      data: (generators) {
        final generator = generators.firstWhere(
          (g) => g.tier == tier,
          orElse: () => throw Exception('Generator not found'),
        );

        if (!ref
            .read(currencyNotifierProvider.notifier)
            .spend(CurrencyType.coin, generator.cost)) {
          return false;
        }

        if (generator.count == 0) {
          _increaseMaximums(generator.tier);
        }

        ref
            .read(coinGeneratorNotifierProvider.notifier)
            .incrementCount(generator.tier);

        return true;
      },
      loading: () => false,
      error: (_, __) => false,
    );
  }

  void _increaseMaximums(int tier) {
    final currencies = ref.read(currencyNotifierProvider);
    final currencyNotifier = ref.read(currencyNotifierProvider.notifier);
    final generators = ref.read(coinGeneratorNotifierProvider).value ?? [];

    final nextTierCost =
        generators.isNotEmpty && tier < generators.length - 1
            ? generators[tier].cost
            : 0.0;

    // Update coin max capacity
    final coinCurrency = currencies[CurrencyType.coin];
    if (coinCurrency != null) {
      final newBaseMax = max(
        nextTierCost,
        (200 * pow(10, tier - 1).toDouble()),
      );
      currencyNotifier.updateBaseMax(CurrencyType.coin, newBaseMax);
    }

    // Update gem limits every 10 tiers
    if (tier % 10 == 0) {
      final gemCurrency = currencies[CurrencyType.gem];
      if (gemCurrency != null) {
        currencyNotifier.updateBaseMax(
          CurrencyType.gem,
          gemCurrency.baseMax + 10,
        );
      }
    }

    // Update energy limit every 5 tiers (limit to 24hrs)
    if (tier % 5 == 0) {
      final energyCurrency = currencies[CurrencyType.energy];
      if (energyCurrency != null && energyCurrency.baseMax < 86400000) {
        currencyNotifier.updateBaseMax(
          CurrencyType.energy,
          energyCurrency.baseMax + 3600000,
        );
      }
    }
  }

  bool upgradeShopItem(int itemId) {
    final shopItemsAsyncValue = ref.read(shopItemNotifierProvider);

    return shopItemsAsyncValue.when(
      data: (items) {
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => throw Exception('Shop item not found'),
        );

        if (item.id == 4) {
          return false;
        }

        if (item.level >= item.maxLevel) {
          return false;
        }

        if (!ref
            .read(currencyNotifierProvider.notifier)
            .spend(CurrencyType.space, item.currentCost.toDouble())) {
          return false;
        }

        // Update shop item level
        ref.read(shopItemNotifierProvider.notifier).upgradeItem(item.id);

        // Apply effect based on shop item type
        switch (item.shopItemEffect) {
          case ShopItemEffect.spaceCapacity:
            ref
                .read(currencyNotifierProvider.notifier)
                .updateMaxMultiplier(CurrencyType.space, item.effectValue);
            break;
          case ShopItemEffect.energyCapacity:
            ref
                .read(currencyNotifierProvider.notifier)
                .updateMaxMultiplier(CurrencyType.energy, item.effectValue);
            break;
          case ShopItemEffect.offlineCoinMultiplier:
            ref
                .read(playerStatsNotifierProvider.notifier)
                .increaseOfflineMultiplier(item.effectValue);
            break;
          case ShopItemEffect.coinCapacity:
            ref
                .read(currencyNotifierProvider.notifier)
                .updateMaxMultiplier(CurrencyType.coin, item.effectValue);
            break;
          default:
            break;
        }

        // Save states
        ref.read(currencyNotifierProvider.notifier).saveCurrencies();
        ref.read(playerStatsNotifierProvider.notifier).save();

        return true;
      },
      loading: () => false,
      error: (_, __) => false,
    );
  }

  bool unlockGenerator(int tier) {
    final generatorsAsyncValue = ref.read(coinGeneratorNotifierProvider);

    return generatorsAsyncValue.when(
      data: (generators) {
        final generator = generators.firstWhere(
          (g) => g.tier == tier,
          orElse: () => throw Exception('Generator not found'),
        );

        if (generator.count < 10) return false;
        if (generator.isUnlocked) return false;

        if (!ref
            .read(currencyNotifierProvider.notifier)
            .spend(CurrencyType.space, generator.upgradeUnlockCost)) {
          return false;
        }

        ref
            .read(coinGeneratorNotifierProvider.notifier)
            .unlockGenerator(generator.tier);

        // Save states
        ref.read(currencyNotifierProvider.notifier).saveCurrencies();
        ref.read(playerStatsNotifierProvider.notifier).save();

        return true;
      },
      loading: () => false,
      error: (_, __) => false,
    );
  }

  bool upgradeGenerator(int tier) {
    final generatorsAsyncValue = ref.read(coinGeneratorNotifierProvider);

    return generatorsAsyncValue.when(
      data: (generators) {
        final generator = generators.firstWhere(
          (g) => g.tier == tier,
          orElse: () => throw Exception('Generator not found'),
        );

        if (generator.count < 10) return false;
        if (!generator.isUnlocked) return false;

        if (!ref
            .read(currencyNotifierProvider.notifier)
            .spend(CurrencyType.coin, generator.upgradeCost)) {
          return false;
        }

        ref
            .read(coinGeneratorNotifierProvider.notifier)
            .upgradeTier(generator.tier);

        // Save states
        ref.read(currencyNotifierProvider.notifier).saveCurrencies();
        ref.read(playerStatsNotifierProvider.notifier).save();

        return true;
      },
      loading: () => false,
      error: (_, __) => false,
    );
  }
}
