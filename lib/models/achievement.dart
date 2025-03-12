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

  // Achievement({
  //   required this.id,
  //   this.action = '',
  //   this.reqUnit = '',
  //   this.rewardUnit = '',
  //   this.requirement = 0,
  //   this.reward = 0,
  // });

  String get formattedRequirement {
    if (requirement >= 1000000) {
      return '${(requirement / 1000000).toStringAsFixed(1)}M';
    } else if (requirement >= 1000) {
      return '${(requirement / 1000).toStringAsFixed(1)}K';
    }
    return requirement.toStringAsFixed(0);
  }

  String get formattedReward {
    if (reward >= 1000000) {
      return '${(reward / 1000000).toStringAsFixed(1)}M';
    } else if (reward >= 1000) {
      return '${(reward / 1000).toStringAsFixed(1)}K';
    }
    return reward.toStringAsFixed(0);
  }

  String get description {
    return '$action ${formattedRequirement} $reqUnit';
  }

  String get rewardText {
    return '${formattedReward} $rewardUnit';
  }
}
