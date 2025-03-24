import 'package:objectbox/objectbox.dart';
import 'currency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/objectbox.g.dart';

class CurrencyRepo {
  final Box<Currency> box;

  CurrencyRepo({required this.box});

  Currency load(CurrencyType type) {
    final existing = box.get(type.index);
    if (existing != null) {
      return existing;
    }
    switch (type) {
      case CurrencyType.coin:
        return Currency(id: CurrencyType.coin.index, count: 10, baseMax: 100);
      case CurrencyType.energy:
        return Currency(
          id: CurrencyType.energy.index,
          baseMax: 43200000,
        ); //millseconds to 12hrs
      case CurrencyType.space:
        return Currency(id: CurrencyType.space.index, baseMax: 5000);
      default:
        assert(false, "unhandled currency type: $type");
        return Currency(id: CurrencyType.unknown.index);
    }
  }

  /// Saves multiple currencies to storage
  Future<void> saveCurrencies(List<Currency> currencies) async {
    box.putManyAsync(currencies);
  }

  Future<void> reset() async {
    box.removeAll();
  }
}
