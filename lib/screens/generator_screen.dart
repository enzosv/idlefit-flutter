import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/helpers/constants.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:idlefit/providers/generator_provider.dart';
import 'package:idlefit/widgets/generator_card.dart';
import '../widgets/currency_bar.dart';

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
          ),
        ),
      ],
    );
  }
}
