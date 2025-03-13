import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/util.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Achievement {
  @Id()
  int id = 0;
  int? dateClaimed;

  // Store enum values as strings in the database
  String action = '';
  String reqUnit = '';
  int requirement = 0;

  @Transient()
  String rewardUnit = '';
  @Transient()
  int reward = 0;

  // Getters and setters for enum properties - marked as @Transient so ObjectBox ignores them
  @Transient()
  QuestAction get questAction => QuestActionExtension.fromJson(action);
  set questAction(QuestAction value) => action = value.toJson();

  @Transient()
  QuestUnit get questReqUnit => QuestUnitExtension.fromJson(reqUnit);
  set questReqUnit(QuestUnit value) => reqUnit = value.toJson();

  @Transient()
  RewardUnit get questRewardUnit => RewardUnitExtension.fromJson(rewardUnit);
  set questRewardUnit(RewardUnit value) => rewardUnit = value.toJson();

  // Achievement({
  //   required this.id,
  //   this.action = '',
  //   this.reqUnit = '',
  //   this.rewardUnit = '',
  //   this.requirement = 0,
  //   this.reward = 0,
  // });

  String get description {
    if (questReqUnit == QuestUnit.energy) {
      return '${questAction.display} ${durationNotation(requirement.toDouble())} ${questReqUnit.display}';
    }
    return '${questAction.display} ${toLettersNotation(requirement.toDouble())} ${questReqUnit.display}';
  }

  String get rewardText {
    if (questRewardUnit == RewardUnit.energy) {
      return durationNotation(reward.toDouble());
    }
    return toLettersNotation(reward.toDouble());
  }

  // TODO: achivement for number of generators purchased
  // TODO: achivement for number of generator upgrades purchased
  // TODO: achivement for number of generator upgrades unlocked
  // TODO: achivement for number of shop items purchased
  // TODO: achivement for number of manual taps
}
