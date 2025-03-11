import 'package:flutter/material.dart';
import 'package:idlefit/widgets/health_stats_card.dart';
import 'package:provider/provider.dart';
import '../services/game_state.dart';
import '../widgets/common_widgets.dart';
import '../util.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    return SafeArea(
      child: Column(
        children: [
          // Currency display
          const CurrencyBar(),

          // Stats cards
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Health data card
                HealthStatsCard(),
                const SizedBox(height: 16),
                // Game stats card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Game Statistics',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text('Total Coins Earned'),
                          trailing: Text(
                            toLettersNotation(gameState.coins.totalEarned),
                          ),
                        ),
                        ListTile(
                          title: const Text('Total Coins Spent'),
                          trailing: Text(
                            toLettersNotation(gameState.coins.totalSpent),
                          ),
                        ),
                        ListTile(
                          title: const Text('Total Gems Earned'),
                          trailing: Text(
                            toLettersNotation(gameState.gems.totalEarned),
                          ),
                        ),
                        ListTile(
                          title: const Text('Total Gems Spent'),
                          trailing: Text(
                            toLettersNotation(gameState.gems.totalSpent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Generator stats
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Generator Statistics',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Divider(),
                        ...gameState.coinGenerators
                            .where((generator) => generator.count > 0)
                            .map(
                              (generator) => ListTile(
                                title: Text(generator.name),
                                subtitle: Text(
                                  '${toLettersNotation(generator.output)} coins/sec',
                                ),
                                trailing: Text('Owned: ${generator.count}'),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
