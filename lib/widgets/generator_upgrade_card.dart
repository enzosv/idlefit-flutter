import 'package:flutter/material.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/services/game_state.dart';
import 'package:idlefit/util.dart';
import 'common_card.dart';

class GeneratorUpgradeCard extends StatelessWidget {
  final GameState gameState;
  final CoinGenerator generator;

  const GeneratorUpgradeCard({
    super.key,
    required this.gameState,
    required this.generator,
  });

  @override
  Widget build(BuildContext context) {
    final needsSpace = !generator.isUnlocked;
    final canAffordSpace = gameState.space.count >= generator.upgradeUnlockCost;
    final canAffordCoins = gameState.coins.count >= generator.upgradeCost;

    final additionalInfo = <Widget>[
      Row(
        children: [
          Text(
            'Current output: ${toLettersNotation(generator.output)} ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Icon(Icons.monetization_on, color: Colors.amber, size: 16),
          Text('/sec', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ];

    if (generator.level < generator.maxLevel) {
      additionalInfo.add(
        Row(
          children: [
            Text(
              'Next level: ${toLettersNotation(generator.outputAtLevel(generator.level + 1))} ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Icon(Icons.monetization_on, color: Colors.amber, size: 16),
            Text('/sec', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    if (needsSpace) {
      return CommonCard(
        title: generator.name,
        rightText: 'Level: ${generator.level}/${generator.maxLevel}',
        description: generator.description,
        additionalInfo: additionalInfo,
        costText: 'Cost: ${toLettersNotation(generator.upgradeUnlockCost)}',
        costColor: canAffordSpace ? Colors.green : Colors.red,
        costIcon: Icon(
          Icons.space_dashboard,
          color: canAffordSpace ? Colors.green : Colors.red,
          size: 20,
        ),
        buttonText: 'Unlock',
        onButtonPressed:
            canAffordSpace ? () => gameState.unlockGenerator(generator) : null,
      );
    }

    if (generator.level < generator.maxLevel) {
      return CommonCard(
        title: generator.name,
        rightText: 'Level: ${generator.level}/${generator.maxLevel}',
        description: generator.description,
        additionalInfo: additionalInfo,
        costText: 'Cost: ${toLettersNotation(generator.upgradeCost)}',
        costColor: canAffordCoins ? Colors.green : Colors.red,
        costIcon: Icon(
          Icons.monetization_on,
          color: canAffordCoins ? Colors.green : Colors.red,
          size: 20,
        ),
        buttonText: 'Upgrade',
        onButtonPressed:
            canAffordCoins ? () => gameState.upgradeGenerator(generator) : null,
      );
    }

    return CommonCard(
      title: generator.name,
      rightText: 'Level: ${generator.level}/${generator.maxLevel}',
      description: generator.description,
      additionalInfo: additionalInfo,
      buttonText: 'MAXED',
      onButtonPressed: null,
    );
  }
}
