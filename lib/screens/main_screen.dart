import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/constants.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/providers/coin_generator_provider.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:idlefit/providers/game_engine_provider.dart';
import 'package:idlefit/widgets/generator_card.dart';
import '../widgets/common_widgets.dart';

class FlameBackground extends FlameGame {
  @override
  Future<void> onLoad() async {
    // Add background animations here
  }
}

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                child: ref
                    .watch(coinGeneratorNotifierProvider)
                    .when(
                      data: (generators) {
                        // Sort generators by tier in descending order
                        final currencies = ref.watch(currencyNotifierProvider);
                        final coinMax = currencies[CurrencyType.coin]?.max ?? 0;

                        // Filter affordable generators and sort by price
                        final affordableGenerators =
                            generators
                                .where((generator) => generator.cost <= coinMax)
                                .toList()
                              ..sort((a, b) => b.tier.compareTo(a.tier));

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: affordableGenerators.length,
                          itemBuilder: (context, index) {
                            final generator = affordableGenerators[index];
                            final generatorIndex = generators.indexWhere(
                              (g) => g.tier == generator.tier,
                            );

                            return GeneratorCard(
                              generator: generator,
                              onBuy: () {
                                ref
                                    .read(gameEngineProvider.notifier)
                                    .buyCoinGenerator(generator.tier);
                              },
                              onUpgrade:
                                  generator.isUnlocked
                                      ? () {
                                        ref
                                            .read(gameEngineProvider.notifier)
                                            .upgradeGenerator(generator.tier);
                                      }
                                      : null,
                              onUnlock:
                                  generator.count >= 10 && !generator.isUnlocked
                                      ? () {
                                        ref
                                            .read(gameEngineProvider.notifier)
                                            .unlockGenerator(generator.tier);
                                      }
                                      : null,
                            );
                          },
                        );
                      },
                      loading:
                          () =>
                              const Center(child: CircularProgressIndicator()),
                      error:
                          (error, stackTrace) =>
                              Center(child: Text('Error: $error')),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
