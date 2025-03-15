import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/main.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/models/game_stats_provider.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:idlefit/providers/game_state_provider.dart';
import 'package:objectbox/objectbox.dart';

class CoinGeneratorNotifier extends StateNotifier<List<CoinGenerator>> {
  final Box<CoinGenerator> box;
  final Ref ref;
  CoinGeneratorNotifier(this.ref, this.box, super.state);

  Future<void> initialize() async {
    state = await _parseCoinGenerators('assets/coin_generators.json');
  }

  bool buyCoinGenerator(CoinGenerator generator) {
    final coins = ref.read(coinProvider);
    if (coins.count < generator.cost) return false;
    final coinsNotifier = ref.read(coinProvider.notifier);
    coinsNotifier.spend(generator.cost);
    generator.count++;
    _updateGenerator(generator);
    ref
        .read(gameStatsProvider.notifier)
        .progressTowards(QuestAction.purchase, QuestUnit.generator, 1);
    if (generator.count > 1) {
      // nothing to unlock
      return true;
    }
    final next = state[generator.tier].cost;
    final newMax = max(
      next * 1.1,
      (200 * pow(10, generator.tier - 1)).toDouble(),
    );
    coinsNotifier.setMax(newMax);

    // TODO: increase max gem every 10 tiers?

    if (generator.tier % 5 == 0) {
      // add 1hr of energy every 5 tiers. max 24hrs
      final energy = ref.read(energyProvider);
      if (energy.baseMax < 86400000) {
        final energyNotifier = ref.read(energyProvider.notifier);
        energyNotifier.setMax(energy.baseMax + 3600000);
      }
    }
    ref.read(gameStateProvider.notifier).save();
    return true;
  }

  bool upgradeGenerator(CoinGenerator generator) {
    final coins = ref.read(coinProvider);
    if (coins.count < generator.upgradeCost ||
        generator.count < 10 ||
        !generator.isUnlocked ||
        generator.level >= generator.maxLevel) {
      return false;
    }
    final coinsNotifier = ref.read(coinProvider.notifier);
    coinsNotifier.spend(generator.upgradeCost);
    generator.level++;
    _updateGenerator(generator);
    ref
        .read(gameStatsProvider.notifier)
        .progressTowards(QuestAction.upgrade, QuestUnit.generator, 1);
    ref.read(gameStateProvider.notifier).save();
    return true;
  }

  bool unlockGenerator(CoinGenerator generator) {
    if (generator.count < 10 || generator.isUnlocked) return false;
    final space = ref.read(spaceProvider);
    if (space.count < generator.upgradeUnlockCost) return false;

    final spaceNotifier = ref.read(spaceProvider.notifier);
    spaceNotifier.spend(generator.upgradeUnlockCost);
    generator.isUnlocked = true;
    _updateGenerator(generator);
    ref.read(gameStateProvider.notifier).save();
    return true;
  }

  double tapGenerator(CoinGenerator generator) {
    final double output = max(generator.tier * 15, generator.singleOutput);
    ref.read(coinProvider.notifier).earn(output);
    ref
        .read(gameStatsProvider.notifier)
        .progressTowards(QuestAction.tap, QuestUnit.generator, 1);
    return output;
  }

  void _updateGenerator(CoinGenerator generator) {
    final newState = List<CoinGenerator>.from(state);
    newState[generator.tier - 1] = generator;
    state = newState;
    box.put(generator);
  }

  Future<List<CoinGenerator>> _parseCoinGenerators(String jsonString) async {
    final String response = await rootBundle.loadString(jsonString);
    final List<dynamic> data = jsonDecode(response);

    return data.map((item) {
      CoinGenerator generator = CoinGenerator.fromJson(item);
      final stored = box.get(generator.tier);
      if (stored == null) {
        return generator;
      }
      generator.count = stored.count;
      generator.level = stored.level;
      generator.isUnlocked = stored.isUnlocked;
      return generator;
    }).toList();
  }
}

final generatorProvider =
    StateNotifierProvider<CoinGeneratorNotifier, List<CoinGenerator>>((ref) {
      return CoinGeneratorNotifier(
        ref,
        ref.read(objectBoxProvider).store.box<CoinGenerator>(),
        [],
      );
    });
