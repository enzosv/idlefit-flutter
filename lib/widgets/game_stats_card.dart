import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../services/game_state.dart';
import '../util.dart';
import '../models/shop_items.dart';

class GameStatsCard extends StatelessWidget {
  const GameStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Game Stats',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Divider(),
            const _DynamicStats(),
            const _StaticStats(),
          ],
        ),
      ),
    );
  }
}

class _DynamicStats extends StatelessWidget {
  const _DynamicStats();

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    return _StatListTile(
      icon: Constants.coinIcon,
      iconColor: Colors.amber,
      title: 'Gains',
      current: gameState.coins.count,
      max: gameState.coins.max,
      perSecond: gameState.passiveOutput,
      earned: gameState.coins.totalEarned,
      spent: gameState.coins.totalSpent,
    );
  }
}

class _StaticStats extends StatelessWidget {
  const _StaticStats();

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    return Column(
      children: [
        _StatListTile(
          icon: Constants.energyIcon,
          iconColor: Colors.greenAccent,
          title: 'Energy',
          current: gameState.energy.count,
          max: gameState.energy.max,
          earned: gameState.energy.totalEarned,
          spent: gameState.energy.totalSpent,
        ),
        _StatListTile(
          icon: Constants.spaceIcon,
          iconColor: Colors.blueAccent,
          title: 'Space',
          current: gameState.space.count,
          max: gameState.space.max,
          earned: gameState.space.totalEarned,
          spent: gameState.space.totalSpent,
        ),
      ],
    );
  }
}

class _StatListTile extends StatelessWidget {
  const _StatListTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.current,
    required this.max,
    this.perSecond,
    required this.earned,
    required this.spent,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final double current;
  final double max;
  final double? perSecond;
  final double earned;
  final double spent;

  String _formatted(double value) {
    return title == "Energy"
        ? durationNotation(value)
        : toLettersNotation(value);
  }

  @override
  Widget build(BuildContext context) {
    String titleText = title;
    if (perSecond != null) {
      titleText = '$title • ${toLettersNotation(perSecond!)}/s';
    }
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(titleText),
      subtitle: Row(
        children: [Text('${_formatted(current)}/${_formatted(max)}')],
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('Earned: ${_formatted(earned)}'),
          Text('Spent: ${_formatted(spent)}'),
        ],
      ),
    );
  }
}
