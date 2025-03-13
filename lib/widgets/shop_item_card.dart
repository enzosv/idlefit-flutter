import 'package:flutter/material.dart';
import 'package:idlefit/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/services/game_state_notifier.dart';
import '../services/game_state.dart';
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

    final gameState = ref.watch(gameStateProvider);
    final gameStateNotifier = ref.read(gameStateProvider.notifier);
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
      affordable: gameState.space.count >= item.currentCost,
      buttonText: isMaxLevel ? 'MAXED' : 'Upgrade',
      onButtonPressed:
          (isMaxLevel || gameState.space.count < item.currentCost)
              ? null
              : () => gameStateNotifier.upgradeShopItem(item),
    );
  }
}
