enum ShopItemEffect { coinMultiplier, healthMultiplier, energyCapacity }

class ShopItem {
  final String id;
  final String name;
  final String description;
  final int cost;
  final ShopItemEffect effect;
  final double effectValue;
  final int maxLevel;
  int level;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.effect,
    required this.effectValue,
    required this.maxLevel,
    this.level = 0,
  });

  int get currentCost {
    // Cost increases with each level
    return (cost * (1.5 * level + 1)).floor();
  }

  String get effectDescription {
    switch (effect) {
      case ShopItemEffect.coinMultiplier:
        return '+${(effectValue * 100).toStringAsFixed(0)}% coin production';
      case ShopItemEffect.healthMultiplier:
        return '+${(effectValue * 100).toStringAsFixed(0)}% health rewards';
      case ShopItemEffect.energyCapacity:
        return '+${effectValue.toStringAsFixed(0)} energy capacity';
    }
  }

  String get currentEffectValue {
    final value = effectValue * level;
    switch (effect) {
      case ShopItemEffect.coinMultiplier:
      case ShopItemEffect.healthMultiplier:
        return '${(value * 100).toStringAsFixed(0)}%';
      case ShopItemEffect.energyCapacity:
        return value.toStringAsFixed(0);
    }
  }
}
