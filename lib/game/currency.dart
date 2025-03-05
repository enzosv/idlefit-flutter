import 'package:objectbox/objectbox.dart';

enum CurrencyType { unknown, coin, gem, space, energy }

@Entity()
class Currency {
  @Id(assignable: true)
  int id = 0;

  double count = 0;
  double totalSpent = 0;
  double totalEarned = 0;

  Currency({required this.id, this.count = 0});

  CurrencyType get type {
    _ensureStableEnumValues();
    return id >= 0 && id < CurrencyType.values.length
        ? CurrencyType.values[id]
        : CurrencyType.unknown;
  }

  void mirror(Currency currency) {
    count = currency.count;
    totalEarned = currency.totalEarned;
    totalSpent = currency.totalSpent;
  }

  void earn(double amount) {
    count += amount;
    totalEarned += amount;
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

enum HealthMetric { unknown, caloriesBurned, steps, minutesExercised }

@Entity()
class HealthData {
  @Id()
  int id = 0;

  @Transient()
  HealthMetric metric = HealthMetric.unknown;
  double today = 0;
  double total = 0;

  int get dbMetric {
    _ensureStableEnumValues();
    return metric.index;
  }

  set dbMetric(int value) {
    _ensureStableEnumValues();
    metric =
        value >= 0 && value < HealthMetric.values.length
            ? HealthMetric.values[value]
            : HealthMetric.unknown;
  }

  void _ensureStableEnumValues() {
    assert(HealthMetric.unknown.index == 0);
    assert(HealthMetric.caloriesBurned.index == 1);
    assert(HealthMetric.steps.index == 2);
    assert(HealthMetric.minutesExercised.index == 3);
  }

  String get todayString {
    return today.round().toString();
  }

  String get totalString {
    return total.round().toString();
  }

  Map<String, dynamic> get json {
    return {'metric': metric, 'today': today, 'total': total};
  }
}
