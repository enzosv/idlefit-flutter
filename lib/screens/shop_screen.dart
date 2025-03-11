import 'package:flutter/material.dart';
import 'package:idlefit/widgets/generator_upgrade_card.dart';
import 'package:provider/provider.dart';
import '../services/game_state.dart';
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

          // Shop items and generator upgrades list
          Expanded(
            child: Consumer<GameState>(
              builder: (context, gameState, child) {
                // Filter generators that can be upgraded (count >= 10)
                final upgradableGenerators =
                    gameState.coinGenerators
                        .where((gen) => gen.count >= 10)
                        .toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Shop items section
                    ...gameState.shopItems.map((item) {
                      final isMaxLevel = item.level >= item.maxLevel;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.name,
                                    style:
                                        Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                  ),
                                  Text('Level: ${item.level}/${item.maxLevel}'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(item.description),
                              if (item.level > 0)
                                Text(
                                  'Current effect: ${item.currentEffectValue}',
                                ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                              : gameState.space.count >=
                                                  item.currentCost
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed:
                                        (isMaxLevel ||
                                                gameState.space.count <
                                                    item.currentCost)
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
                    }),

                    // Generator upgrades section
                    if (upgradableGenerators.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Generator Upgrades',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      ...upgradableGenerators.map((generator) {
                        return GeneratorUpgradeCard(
                          gameState: gameState,
                          generator: generator,
                        );
                      }),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
