import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/widgets/generator_card.dart';
import 'package:idlefit/providers/providers.dart';

class GeneratorsScreen extends StatefulWidget {
  const GeneratorsScreen({super.key});

  @override
  State<GeneratorsScreen> createState() => _GeneratorsScreenState();
}

class _GeneratorsScreenState extends State<GeneratorsScreen> {
  final ScrollController _scrollController = ScrollController();
  CoinGenerator? _previousTopGenerator;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final coinGenerators = ref.watch(generatorProvider);
              final coins = ref.watch(coinProvider);

              // Get affordable generators and sort them
              final affordableGenerators =
                  coinGenerators
                      .where((generator) => generator.cost <= coins.max)
                      .toList()
                    ..sort((a, b) => b.tier.compareTo(a.tier));

              // Identify the new top generator
              final newTopGenerator =
                  affordableGenerators.isNotEmpty
                      ? affordableGenerators.first
                      : null;

              // If the top generator has changed, adjust the scroll position
              if (_previousTopGenerator != null &&
                  newTopGenerator != null &&
                  _previousTopGenerator != newTopGenerator &&
                  _scrollController.hasClients) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Scroll down slightly to keep the second generator at the top
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.minScrollExtent + 100,
                    );
                  }
                });
                // Update previous top generator
                _previousTopGenerator = newTopGenerator;
              }

              return ListView.builder(
                controller: _scrollController,
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
