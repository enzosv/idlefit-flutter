import 'package:flutter/material.dart';
import 'package:idlefit/services/object_box.dart';
import 'package:provider/provider.dart';
import '../models/achievement.dart';
import '../models/achievement_repo.dart';
import 'achievement_card.dart';

class AchievementList extends StatefulWidget {
  const AchievementList({super.key});

  @override
  _AchievementListState createState() => _AchievementListState();
}

class _AchievementListState extends State<AchievementList> {
  List<Achievement> achievements = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final achievementBox =
        Provider.of<ObjectBox>(context, listen: false).store.box<Achievement>();
    final achievementRepo = AchievementRepo(box: achievementBox);
    final achivements = await achievementRepo.loadAchievements();
    print("loaded ${achivements.length} achivements");
    setState(() {
      achievements = achivements;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ...achievements.map((achievement) {
            // final currentProgress = progress[achievement.action] ?? 0;
            return AchievementCard(
              achievement: achievement,
              progress: 1,
              onClaim: () {},
              // onClaim: () => onClaim(achievement, currentProgress),
            );
          }),
        ],
      ),
    );
  }
}
