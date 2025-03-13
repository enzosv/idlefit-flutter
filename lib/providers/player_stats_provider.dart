import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/player_stats.dart';
import 'package:idlefit/models/player_stats_repo.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'objectbox_provider.dart';

part 'player_stats_provider.g.dart';

@Riverpod(keepAlive: true)
class PlayerStatsNotifier extends _$PlayerStatsNotifier {
  late PlayerStatsRepo _repo;

  @override
  PlayerStats build() {
    _repo = PlayerStatsRepo(box: ref.watch(objectBoxStoreProvider).box());
    return _repo.loadPlayerStats();
  }

  void save() {
    _repo.savePlayerStats(state);
  }

  void updateLastGenerated(int timestamp) {
    state = state.copyWith(lastGenerated: timestamp);
    save();
  }

  void updateOfflineMultiplier(double value) {
    state = state.copyWith(offlineCoinMultiplier: value);
    save();
  }

  void increaseOfflineMultiplier(double increment) {
    updateOfflineMultiplier(state.offlineCoinMultiplier + increment);
  }

  void updateDoubleCoinExpiry(int timestamp) {
    state = state.copyWith(doubleCoinExpiry: timestamp);
    save();
  }

  void updateBackgroundState(double coins, double energy, double space) {
    state = state.copyWith(
      backgroundCoins: coins,
      backgroundEnergy: 0.0,
      backgroundSpace: 0.0,
      backgroundEnergySpent: 0.0,
    );
    save();
  }

  void setBackgroundEnergy(double energy) {
    state = state.copyWith(backgroundEnergy: energy);
    save();
  }

  void setBackgroundSpace(double space) {
    state = state.copyWith(backgroundSpace: space);
    save();
  }

  void setBackgroundEnergySpent(double energySpent) {
    state = state.copyWith(backgroundEnergySpent: energySpent);
    save();
  }

  Map<String, double> getBackgroundDifferences(
    double currentCoins,
    double currentEnergy,
    double currentSpace,
  ) {
    return {
      'coins': currentCoins - state.backgroundCoins,
      'energy_earned': state.backgroundEnergy,
      'space': state.backgroundSpace,
      'energy_spent': state.backgroundEnergySpent,
    };
  }
}
