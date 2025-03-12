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
    final allAchievements = await achievementRepo.loadAchievements();

    // Sort achievements by action, reqUnit, and requirement
    allAchievements.sort((a, b) {
      int actionCompare = a.action.compareTo(b.action);
      if (actionCompare != 0) return actionCompare;

      int reqUnitCompare = a.reqUnit.compareTo(b.reqUnit);
      if (reqUnitCompare != 0) return reqUnitCompare;

      return a.requirement.compareTo(b.requirement);
    });

    // Filter achievements to only show those where lower requirements are claimed
    final filteredAchievements =
        allAchievements.where((achievement) {
          // Find all achievements with same action and reqUnit but lower requirement
          final lowerRequirements = allAchievements.where(
            (a) =>
                a.action == achievement.action &&
                a.reqUnit == achievement.reqUnit &&
                a.requirement < achievement.requirement,
          );

          // If there are no lower requirements, show the achievement
          if (lowerRequirements.isEmpty) return true;

          // Only show if all lower requirements are claimed
          return lowerRequirements.every((a) => a.dateClaimed != null);
        }).toList();

    setState(() {
      achievements = filteredAchievements;
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
