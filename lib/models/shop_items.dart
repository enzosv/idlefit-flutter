import 'package:idlefit/models/currency.dart';
import 'package:objectbox/objectbox.dart';

enum ShopItemEffect { unknown, coinMultiplier, healthMultiplier, energyCapacity }

@Entity()
class ShopItem {
  @Id(assignable: true)
  int id;
  int level;
  @Transient()
  int baseCost;
  @Transient()
  String effect;
  @Transient()
  double effectValue;
  @Transient()
  String name;
  @Transient()
  String description;
  @Transient()
  int maxLevel;
  

  ShopItem({
    required this.id,
    this.name = '',
    this.description = '',
    this.baseCost = 0,
    this.effect = '',
    this.effectValue = 0,
    this.maxLevel = 0,
    this.level = 0,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      baseCost: json['baseCost'],
      effect: json['effect'],
      effectValue: json['effectValue'].toDouble(),
      maxLevel: json['maxLevel'],
    );
  }

  ShopItemEffect get shopItemEffect {
    _ensureStableEnumValues();
    return ShopItemEffect.values.byName(effect) ?? ShopItemEffect.unknown;
  }

  CurrencyType get costUnit {
    switch (shopItemEffect) {
      case ShopItemEffect.energyCapacity:
      return CurrencyType.space;
      default:
      return CurrencyType.coin;
    }
  }

    void _ensureStableEnumValues() {
    assert(ShopItemEffect.unknown.index == 0);
    assert(ShopItemEffect.coinMultiplier.index == 1);
    assert(ShopItemEffect.healthMultiplier.index == 2);
    assert(ShopItemEffect.energyCapacity.index == 3);
  }

  int get currentCost {
    // Cost increases with each level
    return (baseCost * (1.5 * level + 1)).floor();
  }

  String get effectDescription {
    switch (shopItemEffect) {
      case ShopItemEffect.coinMultiplier:
        return '+${(effectValue * 100).toStringAsFixed(0)}% coin production';
      case ShopItemEffect.healthMultiplier:
        return '+${(effectValue * 100).toStringAsFixed(0)}% health rewards';
      case ShopItemEffect.energyCapacity:
        return '+${effectValue.toStringAsFixed(0)} energy capacity';
      default:
        return "unknown";
    }
  }

  String get currentEffectValue {
    final value = effectValue * level;
    switch (shopItemEffect) {
      case ShopItemEffect.coinMultiplier:
      case ShopItemEffect.healthMultiplier:
        return '${(value * 100).toStringAsFixed(0)}%';
      case ShopItemEffect.energyCapacity:
        return value.toStringAsFixed(0);
      default:
        return "unknown";
    }
  }
}
