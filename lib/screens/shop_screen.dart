import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';
import '../widgets/common_widgets.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Currency display
          const CurrencyBar(),

          // Shop items list
          Expanded(
            child: Consumer<GameState>(
              builder: (context, gameState, child) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: gameState.shopItems.length,
                  itemBuilder: (context, index) {
                    final item = gameState.shopItems[index];
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
                                Text(
                                  item.name,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                Text('Level: ${item.level}/${item.maxLevel}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(item.description),
                            Text(item.effectDescription),
                            if (item.level > 0)
                              Text(
                                'Current effect: ${item.currentEffectValue}',
                              ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isMaxLevel
                                      ? 'MAXED OUT'
                                      : 'Cost: ${item.currentCost} gems',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isMaxLevel
                                            ? Colors.grey
                                            : gameState.gems >= item.currentCost
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed:
                                      (isMaxLevel ||
                                              gameState.gems < item.currentCost)
                                          ? null
                                          : () =>
                                              gameState.upgradeShopItem(item),
                                  child: const Text('Upgrade'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
