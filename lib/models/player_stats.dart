import 'package:objectbox/objectbox.dart';

@Entity()
class PlayerStats {
  @Id()
  int id = 0; // ObjectBox requires an ID field, we'll use a singleton with ID 1

  // Properties previously stored in storage_service.dart via SharedPreferences
  int lastGenerated = 0;
  int doubleCoinExpiry = 0;
  double offlineCoinMultiplier = 0.5;

  // Background state tracking (previously in GameState)
  double backgroundCoins = 0;
  double backgroundEnergy = 0;
  double backgroundSpace = 0;
  double backgroundEnergySpent = 0;

  PlayerStats({
    this.lastGenerated = 0,
    this.doubleCoinExpiry = 0,
    this.offlineCoinMultiplier = 0.5,
    this.backgroundCoins = 0,
    this.backgroundEnergy = 0,
    this.backgroundSpace = 0,
    this.backgroundEnergySpent = 0,
  });

  // Helper method to update background state
  void updateBackgroundState(double coins, double energy, double space) {
    backgroundCoins = coins;
    backgroundEnergySpent = 0;
    backgroundEnergy = 0;
    backgroundSpace = 0;
  }

  // Helper method to get differences in background earnings
  Map<String, double> getBackgroundDifferences(
    double currentCoins,
    double currentEnergy,
    double currentSpace,
  ) {
    return {
      'coins': currentCoins - backgroundCoins,
      'energy_earned': backgroundEnergy,
      'space': backgroundSpace,
      'energy_spent': backgroundEnergySpent,
    };
  }
}
