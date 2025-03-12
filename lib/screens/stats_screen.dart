import 'package:flutter/material.dart';
import 'package:idlefit/constants.dart';
import 'package:idlefit/widgets/health_stats_card.dart';
import 'package:idlefit/widgets/game_stats_card.dart';
import 'package:provider/provider.dart';
import '../services/game_state.dart';
import '../widgets/common_widgets.dart';
import '../util.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
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

          // Stats cards
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Health data card
                HealthStatsCard(),
                const SizedBox(height: 16),
                // Game stats card
                const GameStatsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
