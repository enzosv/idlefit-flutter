import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_state.dart';
import '../models/shop_items.dart';
import 'common_card.dart';

class ShopItemCard extends StatelessWidget {
  final ShopItem item;

  const ShopItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final isMaxLevel = item.level >= item.maxLevel;

    return CommonCard(
      title: item.name,
      rightText: 'Level: ${item.level}/${item.maxLevel}',
      description: item.description,
      additionalInfo:
          item.level > 0
              ? [Text('Current effect: ${item.currentEffectValue}')]
              : [],
      costText:
          isMaxLevel
              ? 'MAXED OUT'
              : 'Cost: ${item.currentCost} ${item.costUnit.name}',
      costColor:
          isMaxLevel
              ? Colors.grey
              : gameState.space.count >= item.currentCost
              ? Colors.green
              : Colors.red,
      buttonText: 'Upgrade',
      onButtonPressed:
          (isMaxLevel || gameState.space.count < item.currentCost)
              ? null
              : () => gameState.upgradeShopItem(item),
    );
  }
}
