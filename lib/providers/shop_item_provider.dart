import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/helpers/constants.dart';
import 'package:idlefit/helpers/util.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/models/shop_items.dart';
import 'package:idlefit/providers/providers.dart';

class ShopItemNotifier extends Notifier<List<ShopItem>> {
  late final ShopItemsRepository _repo;
  @override
  List<ShopItem> build() {
    final box = ref.read(objectBoxProvider).store.box<ShopItem>();
    _repo = ShopItemsRepository(box);
    _loadShopItems();
    return [];
  }

  Future<void> _loadShopItems() async {
    state = await _repo.loadShopItems('assets/shop_items.json');
    ref.read(gameStateProvider.notifier).recomputePassiveOutput();
  }

  bool upgradeShopItem(ShopItem item) {
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
        ref.read(gameStateProvider.notifier).recomputePassiveOutput();

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
    _repo.saveShopItem(item);
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
    await _repo.clearAll();
    _loadShopItems();
  }
}
