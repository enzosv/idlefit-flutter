import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/constants.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:idlefit/providers/game_engine_provider.dart';
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

    final currencies = ref.watch(currencyNotifierProvider);
    final spaceCount = currencies[CurrencyType.space]?.count ?? 0;
    final isMaxLevel = item.level >= item.maxLevel;

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
      affordable: spaceCount >= item.currentCost,
      buttonText: isMaxLevel ? 'MAXED' : 'Upgrade',
      onButtonPressed:
          (isMaxLevel || spaceCount < item.currentCost)
              ? null
              : () => ref
                  .read(gameEngineProvider.notifier)
                  .upgradeShopItem(item.id),
    );
  }
}
