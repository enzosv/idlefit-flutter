import 'package:flutter/material.dart';
import 'package:idlefit/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/providers/coin_provider.dart';
import 'package:idlefit/providers/shop_item_provider.dart';
import '../models/shop_items.dart';
import 'common_card.dart';
import 'shop_double_coin_card.dart';

class ShopItemCard extends ConsumerWidget {
  final ShopItem item;

  const ShopItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (item.id == 4) {
      return DoubleCoinsCard(item: item);
    }

    final isMaxLevel = item.level >= item.maxLevel;
    final space = ref.watch(spaceProvider);
    return CommonCard(
      title: item.name,
      rightText: 'Level: ${item.level}/${item.maxLevel}',
      description: item.description,
      additionalInfo:
          item.level > 0
              ? [Text('Current effect: ${item.currentEffectValue}')]
              : [],
      cost: isMaxLevel ? null : item.currentCost.toDouble(),
      costIcon: isMaxLevel ? null : Constants.spaceIcon,
      affordable: space.count >= item.currentCost,
      buttonText: isMaxLevel ? 'MAXED' : 'Upgrade',
      onButtonPressed:
          (isMaxLevel || space.count < item.currentCost)
              ? null
              : () => ref.read(shopItemProvider.notifier).upgradeShopItem(item),
    );
  }
}
