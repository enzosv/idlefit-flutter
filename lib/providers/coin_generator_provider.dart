import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'objectbox_provider.dart';

part 'coin_generator_provider.g.dart';

@Riverpod(keepAlive: true)
class CoinGeneratorNotifier extends _$CoinGeneratorNotifier {
  late CoinGeneratorRepo _repo;

  @override
  Future<List<CoinGenerator>> build() async {
    _repo = CoinGeneratorRepo(box: ref.watch(objectBoxStoreProvider).box());
    return _repo.parseCoinGenerators('assets/coin_generators.json');
  }

  Future<void> incrementCount(int tier) async {
    final generators = await future;
    if (generators.any((g) => g.tier == tier)) {
      final newGenerators = [...generators];
      final index = newGenerators.indexWhere((g) => g.tier == tier);
      if (index != -1) {
        final generator = newGenerators[index];
        generator.count++;
        _repo.saveCoinGenerator(generator);
        state = AsyncData(newGenerators);
      }
    }
  }

  Future<void> upgradeTier(int tier) async {
    final generators = await future;
    if (generators.any((g) => g.tier == tier)) {
      final newGenerators = [...generators];
      final index = newGenerators.indexWhere((g) => g.tier == tier);
      if (index != -1) {
        final generator = newGenerators[index];
        generator.level++;
        _repo.saveCoinGenerator(generator);
        state = AsyncData(newGenerators);
      }
    }
  }

  Future<void> unlockGenerator(int tier) async {
    final generators = await future;
    if (generators.any((g) => g.tier == tier)) {
      final newGenerators = [...generators];
      final index = newGenerators.indexWhere((g) => g.tier == tier);
      if (index != -1) {
        final generator = newGenerators[index];
        generator.isUnlocked = true;
        _repo.saveCoinGenerator(generator);
        state = AsyncData(newGenerators);
      }
    }
  }

  double calculateTotalOutput(int timestamp) {
    // Default 0 when async data is loading
    if (state.isLoading || state.hasError) return 0;

    final generators = state.value ?? [];
    double output = 0;

    for (final generator in generators) {
      output += generator.output;
    }

    return output;
  }
}
