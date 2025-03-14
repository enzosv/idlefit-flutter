import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/constants.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/providers/coin_provider.dart';
import 'package:idlefit/providers/generator_provider.dart';
import 'package:idlefit/services/game_state_notifier.dart';
import 'package:idlefit/util.dart';
import 'common_card.dart';

class GeneratorUpgradeCard extends ConsumerWidget {
  final CoinGenerator generator;

  const GeneratorUpgradeCard({super.key, required this.generator});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final coinGeneratorNotifier = ref.read(generatorProvider.notifier);

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
      final space = ref.watch(spaceProvider);
      return CommonCard(
        title: generator.name,
        rightText: 'Level: ${generator.level}/${generator.maxLevel}',
        additionalInfo: additionalInfo,
        cost: generator.upgradeUnlockCost,
        affordable: space.count >= generator.upgradeUnlockCost,
        costIcon: Constants.spaceIcon,
        buttonText: 'Unlock',
        onButtonPressed:
            space.count >= generator.upgradeUnlockCost
                ? () => coinGeneratorNotifier.unlockGenerator(generator)
                : null,
      );
    }

    final isMaxLevel = generator.level >= generator.maxLevel;
    final coins = ref.watch(coinProvider);
    return CommonCard(
      title: generator.name,
      rightText: 'Level: ${generator.level}/${generator.maxLevel}',
      additionalInfo: additionalInfo,
      cost: isMaxLevel ? null : generator.upgradeCost,
      affordable: coins.count >= generator.upgradeCost,
      costIcon: isMaxLevel ? null : Constants.coinIcon,
      buttonText: isMaxLevel ? 'MAXED' : 'Upgrade',
      onButtonPressed:
          (isMaxLevel || coins.count < generator.upgradeCost)
              ? null
              : () => coinGeneratorNotifier.upgradeGenerator(generator),
    );
  }
}
