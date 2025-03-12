import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:idlefit/constants.dart';
import 'package:idlefit/widgets/generator_card.dart';
import 'package:provider/provider.dart';
import '../services/game_state.dart';
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
          top: false,
          child: Column(
            children: [
              Container(
                height: MediaQuery.paddingOf(context).top,
                color: Constants.barColor,
              ),

              // Currency display
              const CurrencyBar(),

              // Generators list
              Expanded(
                child: Consumer<GameState>(
                  builder: (context, gameState, child) {
                    // Filter affordable generators and sort by price
                    final affordableGenerators =
                        gameState.coinGenerators
                            .where(
                              (generator) =>
                                  generator.cost <= gameState.coins.max,
                            )
                            .toList()
                          ..sort((a, b) => b.cost.compareTo(a.cost));

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: affordableGenerators.length,
                      itemBuilder: (context, index) {
                        return GeneratorCard(
                          gameState: gameState,
                          generatorIndex: gameState.coinGenerators.indexOf(
                            affordableGenerators[index],
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
