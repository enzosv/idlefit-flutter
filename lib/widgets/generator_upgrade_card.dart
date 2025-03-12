import 'package:flutter/material.dart';
import 'package:idlefit/constants.dart';
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
    final additionalInfo = <Widget>[
      Row(
        children: [
          Text(
            'Output: ${toLettersNotation(generator.output)} ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Icon(Constants.coinIcon, color: Colors.amber, size: 16),
          Text('/s', style: Theme.of(context).textTheme.bodyMedium),
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
            Icon(Constants.coinIcon, color: Colors.amber, size: 16),
            Text('/s', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    if (!generator.isUnlocked) {
      return CommonCard(
        title: generator.name,
        rightText: 'Level: ${generator.level}/${generator.maxLevel}',
        additionalInfo: additionalInfo,
        cost: generator.upgradeUnlockCost,
        affordable: gameState.space.count >= generator.upgradeUnlockCost,
        costIcon: Constants.spaceIcon,
        buttonText: 'Unlock',
        onButtonPressed:
            gameState.space.count >= generator.upgradeUnlockCost
                ? () => gameState.unlockGenerator(generator)
                : null,
      );
    }

    final isMaxLevel = generator.level >= generator.maxLevel;

    return CommonCard(
      title: generator.name,
      rightText: 'Level: ${generator.level}/${generator.maxLevel}',
      additionalInfo: additionalInfo,
      cost: isMaxLevel ? null : generator.upgradeCost,
      affordable: gameState.coins.count >= generator.upgradeCost,
      costIcon: isMaxLevel ? null : Constants.coinIcon,
      buttonText: isMaxLevel ? 'MAXED' : 'Upgrade',
      onButtonPressed:
          (isMaxLevel || gameState.coins.count < generator.upgradeCost)
              ? null
              : () => gameState.upgradeGenerator(generator),
    );
  }
}
