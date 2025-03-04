import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';
import '../services/health_service.dart';
import '../widgets/common_widgets.dart';
import '../util.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final healthService = Provider.of<HealthService>(context, listen: false);

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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Health Activity',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.directions_walk),
                          title: const Text('Steps'),
                          subtitle: Text('Today: ${healthService.steps}'),
                          trailing: Text('Total: ${gameState.totalSteps}'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.local_fire_department),
                          title: const Text('Calories Burned'),
                          subtitle: Text(
                            'Today: ${healthService.caloriesBurned.round()}',
                          ),
                          trailing: Text(
                            'Total: ${gameState.totalCaloriesBurned.round()}',
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.fitness_center),
                          title: const Text('Exercise Minutes'),
                          subtitle: Text(
                            'Today: ${healthService.exerciseMinutes}',
                          ),
                          trailing: Text(
                            'Total: ${gameState.totalExerciseMinutes}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

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
                            '${shortNotation(gameState.totalCoinsEarned)}',
                          ),
                        ),
                        ListTile(
                          title: const Text('Total Coins Spent'),
                          trailing: Text(
                            '${gameState.totalCoinsSpent.floor()}',
                          ),
                        ),
                        ListTile(
                          title: const Text('Total Gems Earned'),
                          trailing: Text('${gameState.totalGemsEarned}'),
                        ),
                        ListTile(
                          title: const Text('Total Gems Spent'),
                          trailing: Text('${gameState.totalGemsSpent}'),
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
                        ...gameState.generators.map(
                          (generator) => ListTile(
                            title: Text(generator.name),
                            subtitle: Text('${generator.output} coins/sec'),
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
