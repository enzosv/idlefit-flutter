import 'package:idlefit/objectbox.g.dart';

@Entity()
class GameStats {
  @Id(assignable: true)
  int dayTimestamp = 0;
  int generatorsPurchased = 0;
  int generatorsUpgraded = 0;
  int shopItemsPurchased = 0;
  int manualTaps = 0;

  GameStats({
    this.dayTimestamp = 0,
    this.generatorsPurchased = 0,
    this.generatorsUpgraded = 0,
    this.shopItemsPurchased = 0,
    this.manualTaps = 0,
  });

  GameStats copyWith({
    int? generatorsPurchased,
    int? generatorsUpgraded,
    int? shopItemsPurchased,
    int? manualTaps,
  }) {
    return GameStats(
      dayTimestamp: dayTimestamp,
      generatorsPurchased: generatorsPurchased ?? this.generatorsPurchased,
      generatorsUpgraded: generatorsUpgraded ?? this.generatorsUpgraded,
      shopItemsPurchased: shopItemsPurchased ?? this.shopItemsPurchased,
      manualTaps: manualTaps ?? this.manualTaps,
    );
  }
}
