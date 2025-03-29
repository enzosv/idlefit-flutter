import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/widgets/generator_card.dart';
import 'package:idlefit/providers/providers.dart';

class GeneratorsScreen extends StatefulWidget {
  const GeneratorsScreen({super.key});

  @override
  State<GeneratorsScreen> createState() => _GeneratorsScreenState();
}

class _GeneratorsScreenState extends State<GeneratorsScreen> {
  final ScrollController _scrollController = ScrollController();
  int _previousGeneratorCount = 0;
  final GlobalKey _newGeneratorKey = GlobalKey();

  /// Measures the height of the newly added generator card
  double _measureNewCardHeight() {
    final context = _newGeneratorKey.currentContext;
    if (context != null) {
      final renderBox = context.findRenderObject() as RenderBox?;
      return renderBox?.size.height ?? 0;
    }
    return 0;
  }

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
                      .where(
                        (generator) => generator.cost <= max(coins.max, 1000),
                      )
                      .toList()
                    ..sort((a, b) => b.tier.compareTo(a.tier));

              final newGeneratorAdded =
                  affordableGenerators.length > _previousGeneratorCount;

              if (_scrollController.hasClients && newGeneratorAdded) {
                final previousOffset = _scrollController.offset;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_scrollController.hasClients) {
                    return;
                  }
                  final newCardHeight = _measureNewCardHeight();
                  _scrollController.jumpTo(previousOffset + newCardHeight);
                  _scrollController.animateTo(
                    0,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOutBack,
                  );
                });
              }

              _previousGeneratorCount = affordableGenerators.length;

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: affordableGenerators.length,
                itemBuilder: (context, index) {
                  return GeneratorCard(
                    key:
                        index == 0
                            ? _newGeneratorKey
                            : null, // Track first item
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
