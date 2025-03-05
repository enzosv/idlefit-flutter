import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:idlefit/util.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';
import '../widgets/common_widgets.dart';

class FlameBackground extends FlameGame {
  @override
  Future<void> onLoad() async {
    // Add background animations here
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Game background using Flame
        GameWidget(game: FlameBackground()),
        // Game UI overlay
        SafeArea(
          child: Column(
            children: [
              // Currency display
              const CurrencyBar(),

              // Generators list
              Expanded(
                child: Consumer<GameState>(
                  builder: (context, gameState, child) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: gameState.coinGenerators.length,
                      itemBuilder: (context, index) {
                        final generator = gameState.coinGenerators[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      generator.name,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                    ),
                                    Text('Owned: ${generator.count}'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(generator.description),
                                Text(
                                  'Produces: ${shortNotation(generator.baseOutput)} coins/sec',
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Cost: ${shortNotation(generator.cost)} coins',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            gameState.coins.count >=
                                                    generator.cost
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          gameState.coins.count >=
                                                  generator.cost
                                              ? () => gameState
                                                  .buyCoinGenerator(generator)
                                              : null,
                                      child: const Text('Buy'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
