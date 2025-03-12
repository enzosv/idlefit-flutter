import 'package:flutter/material.dart';
import 'package:idlefit/constants.dart';
import 'package:idlefit/widgets/generator_upgrade_card.dart';
import 'package:idlefit/widgets/shop_item_card.dart';
import 'package:provider/provider.dart';
import '../services/game_state.dart';
import '../widgets/common_widgets.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Container(
            height: MediaQuery.paddingOf(context).top,
            color: Constants.barColor,
          ),
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
                    ...gameState.shopItems.map(
                      (item) => ShopItemCard(item: item),
                    ),

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
