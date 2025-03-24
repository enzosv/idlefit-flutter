import 'package:idlefit/providers/currency_provider.dart';
import 'package:objectbox/objectbox.dart';
import 'currency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/main.dart';
import 'package:idlefit/objectbox.g.dart';

class CurrencyRepo {
  final Box<Currency> box;

  CurrencyRepo({required this.box});

  /// Loads all currencies from storage and returns them in a map
  Map<CurrencyType, Currency> _loadCurrencies() {
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
  void _ensureDefaultCurrencies() {
    final existingCurrencies = _loadCurrencies();

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

  Future<void> reset(Ref ref) async {
    box.removeAll();
    _initialize(ref);
  }

  Future<void> _initialize(Ref ref) async {
    _ensureDefaultCurrencies();
    final currencies = _loadCurrencies();

    ref.read(gemProvider.notifier).initialize(currencies[CurrencyType.gem]!);
    ref
        .read(energyProvider.notifier)
        .initialize(currencies[CurrencyType.energy]!);
    ref
        .read(spaceProvider.notifier)
        .initialize(currencies[CurrencyType.space]!);
    ref.read(coinProvider.notifier).initialize(currencies[CurrencyType.coin]!);
  }
}

final currencyRepoProvider = Provider<CurrencyRepo>((ref) {
  final box = ref.read(objectBoxProvider).store.box<Currency>();
  final repo = CurrencyRepo(box: box);
  repo._initialize(ref);
  return repo;
});
