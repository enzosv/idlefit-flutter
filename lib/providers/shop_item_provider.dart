import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/helpers/constants.dart';
import 'package:idlefit/helpers/util.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/models/shop_items.dart';
import 'package:objectbox/objectbox.dart';
import 'package:idlefit/providers/providers.dart';

class ShopItemNotifier extends StateNotifier<List<ShopItem>> {
  final Box<ShopItem> box;
  ShopItemNotifier(this.box, super.state);

  Future<void> initialize() async {
    state = await _parseShopItems('assets/shop_items.json');
  }

  bool upgradeShopItem(ShopItem item, WidgetRef ref) {
    if (ref.read(spaceProvider).count < item.currentCost.toDouble()) {
      return false;
    }

    final spaceNotifier = ref.read(spaceProvider.notifier);

    spaceNotifier.spend(item.currentCost.toDouble());
    item.level++;
    switch (item.shopItemEffect) {
      case ShopItemEffect.spaceCapacity:
        // TODO: new max should be able to afford next level of upgrade
        spaceNotifier.updateMaxMultiplier(item.effectValue);
      case ShopItemEffect.energyCapacity:
        ref.read(energyProvider.notifier).updateMaxMultiplier(item.effectValue);
      case ShopItemEffect.offlineCoinMultiplier:
        //handled simply by updating level
        break;
      case ShopItemEffect.coinCapacity:
        final coinsNotifier = ref.read(coinProvider.notifier);
        coinsNotifier.updateMaxMultiplier(item.effectValue);
      default:
        assert(false, 'Unhandled shop item effect: ${item.shopItemEffect}');
    }
    final newState = List<ShopItem>.from(state);
    newState[item.id - 1] = item;
    state = newState;
    box.putAsync(item);
    ref
        .read(questStatsRepositoryProvider)
        .progressTowards(
          QuestAction.upgrade,
          QuestUnit.shopItem,
          todayTimestamp,
          1,
        );
    return true;
  }

  Future<List<ShopItem>> _parseShopItems(String jsonString) async {
    final String response = await rootBundle.loadString(jsonString);
    final List<dynamic> data = jsonDecode(response);

    return data.map((d) {
      ShopItem item = ShopItem.fromJson(d);
      final stored = box.get(item.id);
      if (stored == null) {
        return item;
      }
      item.level = stored.level;
      return item;
    }).toList();
  }

  double multiplier(ShopItemEffect effect) {
    final double start =
        effect == ShopItemEffect.offlineCoinMultiplier
            ? Constants.baseOfflineCoinsMultiplier
            : 1;
    return state
        .where((item) => item.shopItemEffect == effect)
        .fold(start, (sum, item) => sum + (item.effectValue * item.level));
  }

  Future<void> reset() async {
    box.removeAll();
    initialize();
  }
}
