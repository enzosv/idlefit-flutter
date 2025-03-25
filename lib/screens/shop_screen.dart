import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/widgets/generator_upgrade_card.dart';
import 'package:idlefit/widgets/shop_item_card.dart';
import 'package:idlefit/providers/providers.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Shop items and generator upgrades list
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final shopItems = ref.watch(shopItemProvider);
              final coinGenerators = ref.watch(generatorProvider);
              // Filter generators that can be upgraded (count >= 10)
              final upgradableGenerators =
                  coinGenerators.where((gen) => gen.count >= 10).toList()
                    ..sort((a, b) => b.tier.compareTo(a.tier));

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Shop items section
                  ...shopItems.map((item) => ShopItemCard(item: item)),

                  // Generator upgrades section
                  if (upgradableGenerators.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Add Weight',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    ...upgradableGenerators.map((generator) {
                      return GeneratorUpgradeCard(generator: generator);
                    }),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
