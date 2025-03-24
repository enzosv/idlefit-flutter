import 'package:objectbox/objectbox.dart';
import 'currency.dart';

class CurrencyRepo {
  final Box<Currency> box;

  CurrencyRepo({required this.box});

  /// Loads all currencies from storage and returns them in a map
  Map<CurrencyType, Currency> loadCurrencies() {
    final currencies = box.getAll().toList();
    final currencyMap = <CurrencyType, Currency>{};

    for (final currency in currencies) {
      if (currency.type != CurrencyType.unknown) {
        currencyMap[currency.type] = currency;
      }
    }

    return currencyMap;
  }

  /// Saves multiple currencies to storage
  Future<void> saveCurrencies(List<Currency> currencies) async {
    box.putManyAsync(currencies);
  }

  /// Creates default currencies if they don't exist
  void ensureDefaultCurrencies() {
    final existingCurrencies = loadCurrencies();

    final defaultCurrencies = [
      Currency(id: CurrencyType.coin.index, count: 10, baseMax: 100),
      Currency(id: CurrencyType.gem.index),
      Currency(
        id: CurrencyType.energy.index,
        baseMax: 43200000,
      ), // millseconds to 12hrs
      Currency(id: CurrencyType.space.index, baseMax: 5000),
    ];

    for (final defaultCurrency in defaultCurrencies) {
      if (!existingCurrencies.containsKey(defaultCurrency.type)) {
        box.put(defaultCurrency);
      }
    }
  }

  Future<void> reset() async {
    box.removeAll();
    ensureDefaultCurrencies();
  }
}
