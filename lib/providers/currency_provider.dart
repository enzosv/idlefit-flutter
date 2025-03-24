import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/helpers/util.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/providers/providers.dart';

class CurrencyNotifier extends Notifier<Currency> {
  final CurrencyType type;

  CurrencyNotifier(this.type);

  @override
  Currency build() {
    // Initialize different currency types
    switch (type) {
      case CurrencyType.coin:
        return Currency(id: CurrencyType.coin.index, count: 10, baseMax: 100);
      case CurrencyType.energy:
        return Currency(
          id: CurrencyType.energy.index,
          count: 0,
          baseMax: 43200000,
        ); // 12 hours
      case CurrencyType.space:
        return Currency(id: CurrencyType.space.index, count: 0, baseMax: 5000);
      case CurrencyType.gem:
        return Currency(id: CurrencyType.gem.index, count: 10, baseMax: 100);
      default:
        assert(false, "unhandled currency type $type");
        return Currency(
          id: CurrencyType.unknown.index,
          count: 10,
          baseMax: 100,
        );
    }
  }

  void earn(double amount, {bool allowExcess = false}) {
    state = state.earn(amount, allowExcess);
    ref
        .read(questStatsRepositoryProvider)
        .progressTowards(
          QuestAction.collect,
          state.type.questUnit!,
          todayTimestamp,
          amount,
        );
  }

  void spend(double amount) {
    state = state.spend(amount);
    ref
        .read(questStatsRepositoryProvider)
        .progressTowards(
          QuestAction.spend,
          state.type.questUnit!,
          todayTimestamp,
          amount,
        );
  }

  void setMax(double max) {
    assert(
      max > state.baseMax && max > 0,
      'max must be greater than current max',
    );
    state = state.copyWith(baseMax: max);
  }

  void addMax(double max) {
    assert(max > 0, 'max must be greater than 0');
    state = state.copyWith(baseMax: state.baseMax + max);
  }

  void updateMaxMultiplier(double multiplier) {
    state = state.copyWith(maxMultiplier: state.maxMultiplier + multiplier);
  }
}
