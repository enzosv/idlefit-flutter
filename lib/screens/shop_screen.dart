import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/constants.dart';
import 'package:idlefit/providers/coin_generator_provider.dart';
import 'package:idlefit/providers/shop_item_provider.dart';
import 'package:idlefit/widgets/generator_upgrade_card.dart';
import 'package:idlefit/widgets/shop_item_card.dart';
import '../widgets/common_widgets.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Container(
            height: MediaQuery.paddingOf(context).top,
            color: Constants.barColor,
          ),
          // Currency display
          const CurrencyBar(),

          // Shop items and generator upgrades list
          Expanded(
            child: ref
                .watch(coinGeneratorNotifierProvider)
                .when(
                  data: (generators) {
                    // Get shop items
                    return ref
                        .watch(shopItemNotifierProvider)
                        .when(
                          data: (shopItems) {
                            // Filter generators that can be upgraded (count >= 10)
                            final upgradableGenerators =
                                generators
                                    .where((gen) => gen.count >= 10)
                                    .toList()
                                  ..sort((a, b) => b.tier.compareTo(a.tier));

                            return ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                // Shop items section
                                ...shopItems.map(
                                  (item) => ShopItemCard(item: item),
                                ),

                                // Generator upgrades section
                                if (upgradableGenerators.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  Text(
                                    'Generator Upgrades',
                                    style:
                                        Theme.of(
                                          context,
                                        ).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  ...upgradableGenerators.map((generator) {
                                    return GeneratorUpgradeCard(
                                      generator: generator,
                                    );
                                  }),
                                ],
                              ],
                            );
                          },
                          loading:
                              () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          error:
                              (error, stack) => Center(
                                child: Text('Error loading shop items: $error'),
                              ),
                        );
                  },
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (error, stack) => Center(
                        child: Text('Error loading generators: $error'),
                      ),
                ),
          ),
        ],
      ),
    );
  }
}
