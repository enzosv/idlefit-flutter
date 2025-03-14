import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/daily_quest.dart';
import 'package:idlefit/helpers/util.dart';
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

  QuestAction get questAction {
    return QuestAction.values.byName(action);
  }

  QuestUnit get questUnit {
    return QuestUnit.values.byName(reqUnit);
  }

  CurrencyType get rewardCurrency {
    return CurrencyType.values.byName(rewardUnit);
  }

  // Achievement({
  //   required this.id,
  //   this.action = '',
  //   this.reqUnit = '',
  //   this.rewardUnit = '',
  //   this.requirement = 0,
  //   this.reward = 0,
  // });

  String get description {
    if (questUnit == QuestUnit.energy) {
      return '${questAction.name} ${durationNotation(requirement.toDouble())} ${questUnit.name}';
    }
    return '${questAction.name} ${toLettersNotation(requirement.toDouble())} ${questUnit.name}';
  }

  String get rewardText {
    if (rewardCurrency == CurrencyType.energy) {
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
