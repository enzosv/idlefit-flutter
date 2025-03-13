import 'dart:math';

import 'package:objectbox/objectbox.dart';

enum CurrencyType { unknown, coin, gem, space, energy }

@Entity()
class Currency {
  @Id(assignable: true)
  final int id;

  final double count;
  final double totalSpent;
  final double totalEarned;
  final double baseMax;
  final double maxMultiplier;

  Currency({
    required this.id,
    this.count = 0,
    this.totalSpent = 0,
    this.totalEarned = 0,
    this.baseMax = 100,
    this.maxMultiplier = 1,
  });

  Currency copyWith({
    int? id,
    double? count,
    double? totalSpent,
    double? totalEarned,
    double? baseMax,
    double? maxMultiplier,
  }) {
    return Currency(
      id: id ?? this.id,
      count: count ?? this.count,
      totalSpent: totalSpent ?? this.totalSpent,
      totalEarned: totalEarned ?? this.totalEarned,
      baseMax: baseMax ?? this.baseMax,
      maxMultiplier: maxMultiplier ?? this.maxMultiplier,
    );
  }

  CurrencyType get type {
    _ensureStableEnumValues();
    return id >= 0 && id < CurrencyType.values.length
        ? CurrencyType.values[id]
        : CurrencyType.unknown;
  }

  double get max => baseMax * maxMultiplier;

  Currency earn(double amount, [bool allowExcess = false]) {
    if (!allowExcess) {
      amount = min(amount, max - count);
    }
    if (amount <= 0) {
      return this;
    }
    return copyWith(count: count + amount, totalEarned: totalEarned + amount);
  }

  Currency spend(double amount) {
    if (count < amount) {
      assert(false, "spend amount is more than available");
    }
    return copyWith(count: count - amount, totalSpent: totalSpent + amount);
  }

  void _ensureStableEnumValues() {
    assert(CurrencyType.unknown.index == 0);
    assert(CurrencyType.coin.index == 1);
    assert(CurrencyType.gem.index == 2);
    assert(CurrencyType.space.index == 3);
    assert(CurrencyType.energy.index == 4);
  }
}
