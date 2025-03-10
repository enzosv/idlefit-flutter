import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:idlefit/util.dart';
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
                        return GeneratorCard(
                          gameState: gameState,
                          generatorIndex: index,
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
