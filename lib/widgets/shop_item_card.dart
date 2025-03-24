import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/currency.dart';
import '../models/shop_items.dart';
import 'common_card.dart';
import 'package:idlefit/providers/providers.dart';

class ShopItemCard extends ConsumerWidget {
  final ShopItem item;

  const ShopItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      costCurrency: isMaxLevel ? null : CurrencyType.space,
      affordable: space.count >= item.currentCost,
      buttonText: isMaxLevel ? 'MAXED' : 'Upgrade',
      onButtonPressed:
          (isMaxLevel || space.count < item.currentCost)
              ? null
              : () => ref
                  .read(shopItemProvider.notifier)
                  .upgradeShopItem(item, ref),
    );
  }
}
