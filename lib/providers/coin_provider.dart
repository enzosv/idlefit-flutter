import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';

class CurrencyNotifier extends StateNotifier<Currency> {
  CurrencyNotifier(super.state);

  void initialize(Currency currency) {
    print('initializing coin provider with ${currency.count}');
    state = currency;
  }

  void earn(double amount) {
    state = state.earn(amount);
  }

  void spend(double amount) {
    state = state.spend(amount);
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
    Currency(id: CurrencyType.coin.index, count: 10, baseMax: 100),
  );
});
