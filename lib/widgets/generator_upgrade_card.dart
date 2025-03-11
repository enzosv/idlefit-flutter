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
            Text(
              'Current output: ${toLettersNotation(widget.generator.output)} coins/sec',
            ),
            Text(
              'Next level: ${toLettersNotation(widget.generator.outputAtLevel(widget.generator.level + 1))} coins/sec',
            ),
            const SizedBox(height: 16),
            if (needsSpace) ...[
              Text(
                'Cost: ${toLettersNotation(widget.generator.upgradeUnlockCost)} space',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: canAffordSpace ? Colors.green : Colors.red,
                ),
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
              Text(
                'Cost: ${toLettersNotation(widget.generator.upgradeCost)} coins',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: canAffordCoins ? Colors.green : Colors.red,
                ),
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
