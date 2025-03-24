import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/helpers/util.dart';
import 'package:idlefit/main.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/models/quest_stats.dart';
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

  int get highestTier {
    return state.where((generator) => generator.count > 0).lastOrNull?.tier ??
        0;
  }

  bool buyCoinGenerator(CoinGenerator generator) {
    final coins = ref.read(coinProvider);
    if (coins.count < generator.cost) return false;
    final coinsNotifier = ref.read(coinProvider.notifier);
    coinsNotifier.spend(generator.cost);
    generator.count++;
    _updateGenerator(generator);
    ref
        .read(questStatsRepositoryProvider)
        .progressTowards(
          QuestAction.purchase,
          QuestUnit.generator,
          todayTimestamp,
          1,
        );
    if (generator.count > 1) {
      // nothing to unlock
      return true;
    }
    if (state.length <= generator.tier) {
      // no more tiers to unlock
      return true;
    }

    // make sure next tier is affordable
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
    if (generator.tier % 2 == 0) {
      final space = ref.read(spaceProvider);
      if (space.baseMax < 10000) {
        // add 500 space every 2 tiers
        final spaceNotifier = ref.read(spaceProvider.notifier);
        spaceNotifier.addMax(500);
      }
    }
    ref.read(gameStateProvider.notifier).save();
    return true;
  }

  bool upgradeGenerator(CoinGenerator generator) {
    final space = ref.read(spaceProvider);
    if (space.count < generator.upgradeCost ||
        generator.count < 10 ||
        generator.level >= generator.maxLevel) {
      return false;
    }
    final spaceNotifier = ref.read(spaceProvider.notifier);
    spaceNotifier.spend(generator.upgradeCost);
    generator.level++;
    _updateGenerator(generator);
    ref
        .read(questStatsRepositoryProvider)
        .progressTowards(
          QuestAction.upgrade,
          QuestUnit.generator,
          todayTimestamp,
          1,
        );
    ref.read(gameStateProvider.notifier).save();
    return true;
  }

  double tapGenerator(CoinGenerator generator) {
    final double output = max(generator.tier * 15, generator.singleOutput);
    ref.read(coinProvider.notifier).earn(output);
    ref
        .read(questStatsRepositoryProvider)
        .progressTowards(
          QuestAction.tap,
          QuestUnit.generator,
          todayTimestamp,
          1,
        );
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
      return generator;
    }).toList();
  }

  Future<void> reset() async {
    box.removeAll();
    state = await _parseCoinGenerators('assets/coin_generators.json');
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
