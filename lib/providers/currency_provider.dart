import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/helpers/util.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/providers/daily_quest_provider.dart';

class CurrencyNotifier extends StateNotifier<Currency> {
  final Ref ref;
  CurrencyNotifier(this.ref, super.state);

  void initialize(Currency currency) {
    state = currency;
  }

  void earn(double amount) {
    state = state.earn(amount);
    final questUnit = QuestUnit.values.byNameOrNull(state.type.name);
    if (questUnit == null) {
      return;
    }
    ref
        .read(dailyQuestProvider.notifier)
        .progressTowards(QuestAction.collect, questUnit, amount);
  }

  void spend(double amount) {
    state = state.spend(amount);
    ref
        .read(dailyQuestProvider.notifier)
        .progressTowards(
          QuestAction.spend,
          QuestUnit.values.byName(state.type.name),
          amount,
        );
  }

  void setMax(double max) {
    state = state.copyWith(baseMax: max);
  }

  void updateMaxMultiplier(double multiplier) {
    state = state.copyWith(maxMultiplier: state.maxMultiplier + multiplier);
  }
}

final coinProvider = StateNotifierProvider<CurrencyNotifier, Currency>((ref) {
  return CurrencyNotifier(
    ref,
    Currency(id: CurrencyType.coin.index, count: 10, baseMax: 100),
  );
});

final energyProvider = StateNotifierProvider<CurrencyNotifier, Currency>((ref) {
  return CurrencyNotifier(
    ref,
    Currency(
      id: CurrencyType.energy.index,
      count: 0,
      baseMax: 43200000, //12hrs
    ),
  );
});

final spaceProvider = StateNotifierProvider<CurrencyNotifier, Currency>((ref) {
  return CurrencyNotifier(
    ref,
    Currency(id: CurrencyType.space.index, count: 0, baseMax: 5000),
  );
});

final gemProvider = StateNotifierProvider<CurrencyNotifier, Currency>((ref) {
  return CurrencyNotifier(
    ref,
    Currency(id: CurrencyType.gem.index, count: 10, baseMax: 100),
  );
});
