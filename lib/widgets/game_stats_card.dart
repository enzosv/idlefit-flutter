import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../services/game_state.dart';
import '../util.dart';

class GameStatsCard extends StatelessWidget {
  const GameStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    return Card(
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
            _StatListTile(
              icon: Constants.coinIcon,
              title: 'Gains',
              current: gameState.coins.count,
              earned: gameState.coins.totalEarned,
              spent: gameState.coins.totalSpent,
            ),
            _StatListTile(
              icon: Constants.energyIcon,
              title: 'Energy',
              current: gameState.energy.count,
              earned: gameState.energy.totalEarned,
              spent: gameState.energy.totalSpent,
            ),
            _StatListTile(
              icon: Constants.spaceIcon,
              title: 'Space',
              current: gameState.space.count,
              earned: gameState.space.totalEarned,
              spent: gameState.space.totalSpent,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatListTile extends StatelessWidget {
  const _StatListTile({
    required this.icon,
    required this.title,
    required this.current,
    required this.earned,
    required this.spent,
  });

  final IconData icon;
  final String title;
  final double current;
  final double earned;
  final double spent;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(toLettersNotation(current)),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('Earned: ${toLettersNotation(earned)}'),
          Text('Spent: ${toLettersNotation(spent)}'),
        ],
      ),
    );
  }
}
