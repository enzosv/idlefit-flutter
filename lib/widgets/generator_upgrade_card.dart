import 'package:flutter/material.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/services/game_state.dart';
import 'package:idlefit/util.dart';

class GeneratorUpgradeCard extends StatefulWidget {
  final GameState gameState;
  final CoinGenerator generator;

  const GeneratorUpgradeCard({
    super.key,
    required this.gameState,
    required this.generator,
  });

  @override
  _GeneratorUpgradeCardState createState() => _GeneratorUpgradeCardState();
}

class _GeneratorUpgradeCardState extends State<GeneratorUpgradeCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final needsSpace = !widget.generator.isUnlocked;
    final canAffordSpace =
        widget.gameState.space.count >= widget.generator.upgradeUnlockCost;
    final canAffordCoins =
        widget.gameState.coins.count >= widget.generator.upgradeCost;

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
                  widget.generator.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text('Level: ${widget.generator.level}'),
              ],
            ),
            Row(
              children: [
                Text(
                  'Current output: ${toLettersNotation(widget.generator.output)} ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                Text('/sec', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            Row(
              children: [
                Text(
                  'Next level: ${toLettersNotation(widget.generator.outputAtLevel(widget.generator.level + 1))} ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                Text('/sec', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 16),
            if (needsSpace) ...[
              Row(
                children: [
                  Text(
                    'Cost: ${toLettersNotation(widget.generator.upgradeUnlockCost)} ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: canAffordSpace ? Colors.green : Colors.red,
                    ),
                  ),
                  Icon(
                    Icons.space_dashboard,
                    color: canAffordSpace ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed:
                      canAffordSpace
                          ? () {
                            widget.gameState.unlockGenerator(widget.generator);
                          }
                          : null,
                  child: const Text('Unlock Upgrades'),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Text(
                    'Cost: ${toLettersNotation(widget.generator.upgradeCost)} ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: canAffordCoins ? Colors.green : Colors.red,
                    ),
                  ),
                  Icon(
                    Icons.monetization_on,
                    color: canAffordCoins ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed:
                      canAffordCoins
                          ? () {
                            widget.gameState.upgradeGenerator(widget.generator);
                          }
                          : null,
                  child: const Text('Upgrade'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
