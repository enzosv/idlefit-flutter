import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/currency_repo.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'objectbox_provider.dart';

part 'currency_provider.g.dart';

@Riverpod(keepAlive: true)
class CurrencyNotifier extends _$CurrencyNotifier {
  late CurrencyRepo _repo;

  @override
  Map<CurrencyType, Currency> build() {
    _repo = CurrencyRepo(box: ref.watch(objectBoxStoreProvider).box());
    _repo.ensureDefaultCurrencies();
    return _repo.loadCurrencies();
  }

  Currency getCurrency(CurrencyType type) {
    return state[type] ?? Currency(id: type.index);
  }

  void saveCurrencies() {
    _repo.saveCurrencies(state.values.toList());
  }

  bool spend(CurrencyType type, double amount) {
    final currency = state[type];
    if (currency == null || currency.count < amount) {
      return false;
    }

    final updated =
        Currency(id: currency.id)
          ..mirror(currency)
          ..spend(amount);

    state = {...state, type: updated};
    saveCurrencies();
    return true;
  }

  double earn(CurrencyType type, double amount, {bool allowExcess = false}) {
    final currency = state[type] ?? Currency(id: type.index);
    final earned = currency.earn(amount, allowExcess);

    state = {...state, type: currency};
    saveCurrencies();
    return earned;
  }

  void updateMaxMultiplier(CurrencyType type, double value) {
    final currency = state[type];
    if (currency == null) return;

    final updated =
        Currency(id: currency.id)
          ..mirror(currency)
          ..maxMultiplier += value;

    state = {...state, type: updated};
    saveCurrencies();
  }

  void updateBaseMax(CurrencyType type, double value) {
    final currency = state[type];
    if (currency == null) return;

    final updated =
        Currency(id: currency.id)
          ..mirror(currency)
          ..baseMax = value;

    state = {...state, type: updated};
    saveCurrencies();
  }
}
