import 'package:idlefit/models/currency.dart';
import 'package:idlefit/repositories/base_entity_repo.dart';
import 'package:objectbox/objectbox.dart';

class CurrencyRepo extends BaseEntityRepo<Currency> {
  CurrencyRepo({required Box<Currency> box}) : super(box: box);

  // Get currency by type
  Currency? getByType(CurrencyType type) {
    final allCurrencies = getAll();
    final matching = allCurrencies.where((c) => c.type == type);
    return matching.isNotEmpty ? matching.first : null;
  }

  // Get or create currency by type
  Currency getOrCreate(
    CurrencyType type, {
    double initialCount = 0,
    double initialMax = 100,
  }) {
    final existing = getByType(type);
    if (existing != null) {
      return existing;
    }

    final currency = Currency(
      id: type.index,
      count: initialCount,
      baseMax: initialMax,
    );
    save(currency);
    return currency;
  }

  /// Loads all currencies from storage and returns them in a map
  Map<CurrencyType, Currency> loadCurrencies() {
    final currencies = getAll().toList();
    final currencyMap = <CurrencyType, Currency>{};

    for (final currency in currencies) {
      currencyMap[currency.type] = currency;
    }

    return currencyMap;
  }

  /// Saves multiple currencies to storage
  void saveCurrencies(List<Currency> currencies) {
    for (final currency in currencies) {
      save(currency);
    }
  }

  /// Ensures that all default currencies exist in storage
  void ensureDefaultCurrencies() {
    final existingCurrencies = loadCurrencies();

    final defaultCurrencies = [
      Currency(id: CurrencyType.coin.index, count: 0, baseMax: 100),
      Currency(id: CurrencyType.gem.index, count: 0, baseMax: 10),
      Currency(id: CurrencyType.energy.index, count: 3600, baseMax: 3600),
      Currency(id: CurrencyType.space.index, count: 0, baseMax: 100),
    ];

    for (final defaultCurrency in defaultCurrencies) {
      if (!existingCurrencies.containsKey(defaultCurrency.type)) {
        save(defaultCurrency);
      }
    }
  }
}
