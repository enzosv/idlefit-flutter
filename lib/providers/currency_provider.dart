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
    return ref.read(currencyRepoProvider).load(type);
  }

  void reset() {
    state = ref.read(currencyRepoProvider).load(type);
  }

  void earn(double amount, {bool allowExcess = false}) {
    assert(
      allowExcess && type == CurrencyType.space && amount > 40000,
      "doubtable steps earned $amount",
    );
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
