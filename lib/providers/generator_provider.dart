import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/helpers/util.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/providers/providers.dart';

class CoinGeneratorNotifier extends Notifier<List<CoinGenerator>> {
  late final CoinGeneratorRepository _repo;

  @override
  List<CoinGenerator> build() {
    final box = ref.read(objectBoxProvider).store.box<CoinGenerator>();
    _repo = CoinGeneratorRepository(box);
    _loadCoinGenerators();
    return [];
  }

  Future<void> _loadCoinGenerators() async {
    state = await _repo.loadCoinGenerators('assets/coin_generators.json');
  }

  int get highestTier {
    return state.where((generator) => generator.count > 0).lastOrNull?.tier ??
        0;
  }

  bool buyCoinGenerator(CoinGenerator generator, WidgetRef ref) {
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

  bool upgradeGenerator(CoinGenerator generator, WidgetRef ref) {
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

  double tapGenerator(CoinGenerator generator, WidgetRef ref) {
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
    _repo.saveGenerator(generator);
  }

  Future<void> reset() async {
    _repo.clearAll();
    _loadCoinGenerators();
  }
}
