import 'dart:math';

import 'package:objectbox/objectbox.dart';

enum CurrencyType { unknown, coin, gem, space, energy }

@Entity()
class Currency {
  @Id(assignable: true)
  int id = 0;

  double count = 0;
  double totalSpent = 0;
  double totalEarned = 0;
  double baseMax = 100;
  double maxMultiplier = 1;

  Currency({required this.id, this.count = 0, this.baseMax = 100});

  CurrencyType get type {
    _ensureStableEnumValues();
    return id >= 0 && id < CurrencyType.values.length
        ? CurrencyType.values[id]
        : CurrencyType.unknown;
  }

  double get max {
    return baseMax * maxMultiplier;
  }

  void mirror(Currency currency) {
    count = currency.count;
    totalEarned = currency.totalEarned;
    totalSpent = currency.totalSpent;
    baseMax = currency.baseMax;
    maxMultiplier = currency.maxMultiplier;
  }

  double earn(double amount, [bool allowExcess = false]) {
    if (!allowExcess) {
      amount = min(amount, max - count);
    }
    if (amount <= 0) {
      // TODO: convert unearned coins to energy
      return 0;
    }
    count += amount;
    totalEarned += amount;
    return amount;
  }

  bool spend(double amount) {
    if (count < amount) {
      return false;
    }
    count -= amount;
    totalSpent += amount;
    return true;
  }

  void _ensureStableEnumValues() {
    assert(CurrencyType.unknown.index == 0);
    assert(CurrencyType.coin.index == 1);
    assert(CurrencyType.gem.index == 2);
    assert(CurrencyType.space.index == 3);
    assert(CurrencyType.energy.index == 4);
  }
}
