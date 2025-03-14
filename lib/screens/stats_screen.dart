import 'package:flutter/material.dart';
import 'package:idlefit/helpers/constants.dart';
import 'package:idlefit/widgets/achievement_list.dart';
import 'package:idlefit/widgets/health_stats_card.dart';
import 'package:idlefit/widgets/game_stats_card.dart';
import 'package:idlefit/widgets/banner_ad_widget.dart';
import 'package:idlefit/widgets/daily_quest_list.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Container(
            height: MediaQuery.paddingOf(context).top,
            color: Constants.barColor,
          ),
          // TODO: do not show until user has tier 9 generator
          const BannerAdWidget(),
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
                const SizedBox(height: 16),
                // Daily quests
                const DailyQuestList(),
                const SizedBox(height: 16),
                // Achievement list
                const AchievementList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
