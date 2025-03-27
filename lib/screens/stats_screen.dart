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
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              HealthStatsCard(),
              SizedBox(height: 16),
              QuestList(questType: QuestType.daily),
              SizedBox(height: 16),
              QuestList(questType: QuestType.achievement),
              SizedBox(height: 16),
              GameStatsCard(),
            ],
          ),
        ),
        BannerAdWidget(),
      ],
    );
  }
}
