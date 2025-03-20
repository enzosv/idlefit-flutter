import 'dart:math';

import 'package:flutter/material.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:objectbox/objectbox.dart';

enum CurrencyType { unknown, coin, gem, space, energy }

extension CurrencyTypeExtension on CurrencyType {
  QuestUnit? get questUnit {
    switch (this) {
      case CurrencyType.coin:
        return QuestUnit.coin;
      case CurrencyType.space:
        return QuestUnit.space;
      case CurrencyType.energy:
        return QuestUnit.energy;
      default:
        return null;
    }
  }

  IconData get icon {
    switch (this) {
      case CurrencyType.coin:
        return Icons.speed;
      case CurrencyType.space:
        return Icons.space_dashboard_rounded;
      case CurrencyType.energy:
        return Icons.bolt_rounded;
      default:
        return Icons.question_mark_rounded;
    }
  }

  Color get color {
    switch (this) {
      case CurrencyType.coin:
        return Colors.amber;
      case CurrencyType.space:
        return Colors.blueAccent;
      case CurrencyType.energy:
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  Icon iconWithSize(double size) {
    return Icon(icon, color: color, size: size);
  }
}

@Entity()
class Currency {
  @Id(assignable: true)
  final int id;

  final double count;
  final double totalEarned;
  final double baseMax;
  final double maxMultiplier;

  double get totalSpent {
    return totalEarned - count;
  }

  Currency({
    required this.id,
    this.count = 0,
    this.totalEarned = 0,
    this.baseMax = 100,
    this.maxMultiplier = 1,
  });

  Currency copyWith({
    double? count,
    double? totalSpent,
    double? totalEarned,
    double? baseMax,
    double? maxMultiplier,
  }) {
    return Currency(
      id: id,
      count: count ?? this.count,
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
