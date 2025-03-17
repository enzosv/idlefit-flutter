import 'package:idlefit/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class GameStats {
  @Id(assignable: true)
  int dayTimestamp = 0;
  int generatorsPurchased = 0;
  int generatorsUpgraded = 0;
  int shopItemsUpgraded = 0;
  int generatorsTapped = 0;
  int adsWatched = 0;

  // alraedy tracked in health service
  double caloriesBurned = 0;
  int stepsWalked = 0;

  // already tracked in currency model
  // but not split into days
  double coinsCollected = 0;
  double spaceCollected = 0;
  double energyCollected = 0;
  double energySpent = 0;
  double coinsSpent = 0;
  double spaceSpent = 0;

  GameStats({
    this.dayTimestamp = 0,
    this.generatorsPurchased = 0,
    this.generatorsUpgraded = 0,
    this.shopItemsUpgraded = 0,
    this.generatorsTapped = 0,
    this.adsWatched = 0,
    this.caloriesBurned = 0,
    this.stepsWalked = 0,
    this.coinsCollected = 0,
    this.spaceCollected = 0,
    this.energyCollected = 0,
    this.energySpent = 0,
    this.coinsSpent = 0,
    this.spaceSpent = 0,
  });

  GameStats copyWith({
    int? generatorsPurchased,
    int? generatorsUpgraded,
    int? shopItemsUpgraded,
    int? generatorsTapped,
    int? adsWatched,
    double? caloriesBurned,
    int? stepsWalked,
    double? coinsCollected,
    double? spaceCollected,
    double? energyCollected,
    double? energySpent,
    double? coinsSpent,
    double? spaceSpent,
  }) {
    return GameStats(
      dayTimestamp: dayTimestamp,
      generatorsPurchased: generatorsPurchased ?? this.generatorsPurchased,
      generatorsUpgraded: generatorsUpgraded ?? this.generatorsUpgraded,
      shopItemsUpgraded: shopItemsUpgraded ?? this.shopItemsUpgraded,
      generatorsTapped: generatorsTapped ?? this.generatorsTapped,
      adsWatched: adsWatched ?? this.adsWatched,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      stepsWalked: stepsWalked ?? this.stepsWalked,
      coinsCollected: coinsCollected ?? this.coinsCollected,
      spaceCollected: spaceCollected ?? this.spaceCollected,
      energyCollected: energyCollected ?? this.energyCollected,
      energySpent: energySpent ?? this.energySpent,
      coinsSpent: coinsSpent ?? this.coinsSpent,
      spaceSpent: spaceSpent ?? this.spaceSpent,
    );
  }
}
