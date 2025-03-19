import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/helpers/util.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/providers/daily_currency_provider.dart';

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
        .read(dailyCurrencyProvider.notifier)
        .updateToday(state.type, amount, true);
  }

  void spend(double amount) {
    state = state.spend(amount);
    ref
        .read(dailyCurrencyProvider.notifier)
        .updateToday(state.type, amount, false);
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
