import 'package:flutter/material.dart';
import 'package:idlefit/widgets/health_stats_card.dart';
import 'package:idlefit/widgets/game_stats_card.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Container(height: MediaQuery.paddingOf(context).top),

          // Stats cards
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Game stats card
                const GameStatsCard(),
                const SizedBox(height: 16),
                // Health data card
                HealthStatsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
