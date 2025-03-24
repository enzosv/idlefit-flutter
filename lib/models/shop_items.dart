import 'package:idlefit/helpers/util.dart';
import 'package:idlefit/models/currency.dart';
import 'package:objectbox/objectbox.dart';
import 'dart:convert';

import 'package:flutter/services.dart';

enum ShopItemEffect {
  unknown,
  coinMultiplier,
  healthMultiplier,
  energyCapacity,
  spaceCapacity,
  offlineCoinMultiplier,
  coinCapacity,
}

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
    return ShopItemEffect.values.byNameOrNull(effect) ?? ShopItemEffect.unknown;
  }

  CurrencyType get costUnit {
    switch (shopItemEffect) {
      default:
        return CurrencyType.space;
    }
  }

  void _ensureStableEnumValues() {
    assert(ShopItemEffect.unknown.index == 0);
    assert(ShopItemEffect.coinMultiplier.index == 1);
    assert(ShopItemEffect.healthMultiplier.index == 2);
    assert(ShopItemEffect.energyCapacity.index == 3);
    assert(ShopItemEffect.spaceCapacity.index == 4);
    assert(ShopItemEffect.offlineCoinMultiplier.index == 5);
    assert(ShopItemEffect.coinCapacity.index == 6);
  }

  int get currentCost {
    // Cost increases with each level
    return (baseCost * (1.5 * level + 1)).floor();
  }

  String get currentEffectValue {
    final value = effectValue * level;
    switch (shopItemEffect) {
      default:
        return '+${(value * 100).toStringAsFixed(0)}%';
    }
  }
}

class ShopItemsRepository {
  final Box<ShopItem> _box;

  ShopItemsRepository(this._box);

  Future<List<ShopItem>> loadShopItems(String jsonString) async {
    final String response = await rootBundle.loadString(jsonString);
    final List<dynamic> data = jsonDecode(response);

    return data.map((d) {
      ShopItem item = ShopItem.fromJson(d);
      final stored = _box.get(item.id);
      if (stored == null) {
        return item;
      }
      item.level = stored.level;
      return item;
    }).toList();
  }

  Future<void> saveShopItem(ShopItem item) async {
    _box.putAsync(item);
  }

  Future<void> clearAll() async {
    _box.removeAllAsync();
  }
}
