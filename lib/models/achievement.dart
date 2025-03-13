import 'package:idlefit/models/currency.dart';
import 'package:idlefit/util.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Achievement {
  @Id()
  int id = 0;
  int? dateClaimed;

  String action = '';
  String reqUnit = '';
  int requirement = 0;

  @Transient()
  String rewardUnit = '';
  @Transient()
  int reward = 0;

  CurrencyType get rewardCurrency {
    switch (rewardUnit) {
      case 'space':
        return CurrencyType.space;
      case 'energy':
        return CurrencyType.energy;
      case 'coin':
        return CurrencyType.coin;
      default:
        return CurrencyType.coin;
    }
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
    if (reqUnit == "energy") {
      return '$action ${durationNotation(requirement.toDouble())} $reqUnit';
    }
    return '$action ${toLettersNotation(requirement.toDouble())} $reqUnit';
  }

  String get rewardText {
    if (rewardUnit == "energy") {
      return durationNotation(reward.toDouble());
    }
    return toLettersNotation(reward.toDouble());
  }
}
