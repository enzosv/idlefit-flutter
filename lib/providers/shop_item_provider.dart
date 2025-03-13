import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/shop_items.dart';
import 'package:idlefit/models/shop_items_repo.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'objectbox_provider.dart';

part 'shop_item_provider.g.dart';

@Riverpod(keepAlive: true)
class ShopItemNotifier extends _$ShopItemNotifier {
  late ShopItemsRepo _repo;

  @override
  Future<List<ShopItem>> build() async {
    _repo = ShopItemsRepo(box: ref.watch(objectBoxStoreProvider).box());
    return _repo.parseShopItems('assets/shop_items.json');
  }

  Future<void> upgradeItem(int id) async {
    final items = await future;
    if (items.any((item) => item.id == id)) {
      final newItems = [...items];
      final index = newItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        final item = newItems[index];
        item.level++;
        _repo.saveShopItem(item);
        state = AsyncData(newItems);
      }
    }
  }

  double getMultiplierForEffect(ShopItemEffect effect) {
    if (state.isLoading || state.hasError) return 0;

    final items = state.value ?? [];
    double multiplier = 0;

    for (final item in items) {
      if (item.shopItemEffect == effect) {
        multiplier += item.effectValue * item.level;
      }
    }

    return multiplier;
  }
}
