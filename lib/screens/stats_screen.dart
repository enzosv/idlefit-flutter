import 'package:flutter/material.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/widgets/health_stats_card.dart';
import 'package:idlefit/widgets/game_stats_card.dart';
import 'package:idlefit/widgets/banner_ad_widget.dart';
import 'package:idlefit/widgets/quest_list.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spacer = SizedBox(height: 16);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const HealthStatsCard(),
              spacer,
              // Daily quests
              const QuestList(questType: QuestType.daily),
              spacer,
              // Achievement list
              const QuestList(questType: QuestType.achievement),
              spacer,
              const GameStatsCard(),
            ],
          ),
        ),
        const BannerAdWidget(),
      ],
    );
  }
}
