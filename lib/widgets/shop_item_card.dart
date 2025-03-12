import 'package:flutter/material.dart';
import 'package:idlefit/widgets/card_button.dart';
import 'package:provider/provider.dart';
import '../services/game_state.dart';
import '../models/shop_items.dart';

class ShopItemCard extends StatelessWidget {
  final ShopItem item;

  const ShopItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final isMaxLevel = item.level >= item.maxLevel;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                Text('Level: ${item.level}/${item.maxLevel}'),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.description),
            if (item.level > 0)
              Text('Current effect: ${item.currentEffectValue}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isMaxLevel
                      ? 'MAXED OUT'
                      : 'Cost: ${item.currentCost} ${item.costUnit.name}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        isMaxLevel
                            ? Colors.grey
                            : gameState.space.count >= item.currentCost
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
                CardButton(
                  text: 'Upgrade',
                  onPressed:
                      (isMaxLevel || gameState.space.count < item.currentCost)
                          ? null
                          : () => gameState.upgradeShopItem(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
