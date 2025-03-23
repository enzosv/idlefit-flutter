import 'package:flutter/material.dart';
import 'package:idlefit/helpers/constants.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/widgets/health_stats_card.dart';
import 'package:idlefit/widgets/game_stats_card.dart';
import 'package:idlefit/widgets/banner_ad_widget.dart';
import 'package:idlefit/widgets/quest_list.dart';
import '../widgets/currency_bar.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spacer = SizedBox(height: 16);
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Container(
            height: MediaQuery.paddingOf(context).top,
            color: Constants.barColor,
          ),
          const CurrencyBar(),
          // Stats cards`
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const HealthStatsCard(),
                spacer,
                const GameStatsCard(),
                spacer,
                // Daily quests
                const QuestList(questType: QuestType.daily),
                spacer,
                // Achievement list
                const QuestList(questType: QuestType.achievement),
              ],
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
