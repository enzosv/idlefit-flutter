import 'package:idlefit/helpers/util.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/objectbox.g.dart';

// Define enums for quest properties
enum QuestAction { unknown, spend, walk, watch, burn, collect }

enum QuestUnit { unknown, coin, steps, ad, calories, energy, space }

@Entity()
class DailyQuest {
  @Id()
  int id = 0;

  // Store enum values as strings in the database
  String action = '';
  String unit = '';
  String rewardUnit = '';

  int requirement = 0;
  int reward = 0;
  double progress = 0; // Track progress
  int dateAssigned = 0;
  bool isClaimed = false;

  DailyQuest();

  QuestAction get questAction {
    return QuestAction.values.byNameOrNull(action) ?? QuestAction.unknown;
  }

  QuestUnit get questUnit {
    return QuestUnit.values.byNameOrNull(unit) ?? QuestUnit.unknown;
  }

  CurrencyType get rewardCurrency {
    return CurrencyType.values.byNameOrNull(rewardUnit) ?? CurrencyType.unknown;
  }

  bool get isCompleted => progress >= requirement;

  factory DailyQuest.fromJson(Map<String, dynamic> json) {
    final quest =
        DailyQuest()
          ..action = json['action']
          ..unit = json['unit']
          ..rewardUnit = json['reward_unit']
          ..requirement = json['requirement']
          ..reward = json['reward'];
    return quest;
  }

  DailyQuest updateProgress(double amount) {
    if (amount <= 0) {
      return this;
    }
    return copyWith(progress: progress + amount);
  }

  DailyQuest claim() {
    if (isClaimed || !isCompleted) {
      return this;
    }
    return copyWith(isClaimed: true);
  }

  String get description {
    if (questUnit == QuestUnit.space && questAction == QuestAction.collect) {
      // convert collect space to walk steps
      return 'Walk ${toLettersNotation(requirement.toDouble())} steps';
    }
    return '${questAction.name.capitalize()} ${toLettersNotation(requirement.toDouble())} ${questUnit.name}';
  }

  DailyQuest copyWith({double? progress, bool? isClaimed}) {
    return DailyQuest()
      ..action = action
      ..unit = unit
      ..rewardUnit = rewardUnit
      ..requirement = requirement
      ..reward = reward
      ..progress = progress ?? this.progress
      ..dateAssigned = dateAssigned
      ..isClaimed = isClaimed ?? this.isClaimed;
  }
}
