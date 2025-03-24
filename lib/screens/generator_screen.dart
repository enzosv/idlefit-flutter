import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/widgets/generator_card.dart';
import 'package:idlefit/providers/providers.dart';

class FlameBackground extends FlameGame {
  @override
  Future<void> onLoad() async {
    // Add background animations here
  }
}

class GeneratorsScreen extends StatelessWidget {
  const GeneratorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // GameWidget(game: FlameBackground()),

        // Generators list
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final coinGenerators = ref.watch(generatorProvider);
              final coins = ref.watch(coinProvider);

              // Filter affordable generators and sort by price
              final affordableGenerators =
                  coinGenerators
                      .where((generator) => generator.cost <= coins.max)
                      .toList()
                    ..sort((a, b) => b.tier.compareTo(a.tier));
              // TODO: new generator should require scroll up
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: affordableGenerators.length,
                itemBuilder: (context, index) {
                  return GeneratorCard(
                    generatorIndex: coinGenerators.indexOf(
                      affordableGenerators[index],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
