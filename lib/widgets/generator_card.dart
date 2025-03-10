import 'package:flutter/material.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/services/game_state.dart';
import 'package:idlefit/util.dart';
import 'package:provider/provider.dart';

class GeneratorCard extends StatelessWidget {
  final GameState gameState;
  final int generatorIndex;

  const GeneratorCard({
    Key? key,
    required this.gameState,
    required this.generatorIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final generator = gameState.coinGenerators[generatorIndex];
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
                  generator.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('Owned: ${generator.count}'),
              ],
            ),
            const SizedBox(height: 8),
            Text(generator.description),
            Text(
              'Produces: ${toLettersNotation(generator.baseOutput)} coins/sec',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cost: ${toLettersNotation(generator.cost)} coins',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        gameState.coins.count >= generator.cost
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      gameState.coins.count >= generator.cost
                          ? () => gameState.buyCoinGenerator(generator)
                          : null,
                  child: const Text('Buy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
