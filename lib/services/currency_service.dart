import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/currency_repo.dart';

class CurrencyService {
  static const _calorieToEnergyMultiplier =
      72000.0; // 1 calorie = 72 seconds of idle fuel

  late final Currency coins;
  late final Currency gems;
  late final Currency energy;
  late final Currency space;

  final CurrencyRepo _currencyRepo;

  CurrencyService({required CurrencyRepo currencyRepo})
    : _currencyRepo = currencyRepo;

  Future<void> initialize() async {
    // Ensure default currencies exist and load them
    _currencyRepo.ensureDefaultCurrencies();
    final currencies = _currencyRepo.loadCurrencies();
    coins = currencies[CurrencyType.coin]!;
    gems = currencies[CurrencyType.gem]!;
    energy = currencies[CurrencyType.energy]!;
    space = currencies[CurrencyType.space]!;
  }

  void saveCurrencies() {
    _currencyRepo.saveCurrencies([coins, energy, gems, space]);
  }

  // Coin operations
  bool canSpendCoins(double amount) {
    return coins.count >= amount;
  }

  void spendCoins(double amount) {
    coins.spend(amount);
  }

  void earnCoins(double amount) {
    coins.earn(amount);
  }

  void updateCoinMax(double newMax) {
    coins.baseMax = newMax;
  }

  void increaseCoinMaxMultiplier(double amount) {
    coins.maxMultiplier += amount;
  }

  // Gem operations
  void earnGems(double amount) {
    gems.earn(amount);
  }

  void increaseGemMax(double amount) {
    gems.baseMax += amount;
  }

  // Energy operations
  void spendEnergy(double amount) {
    energy.spend(amount);
  }

  double convertCaloriesToEnergy(double calories) {
    return energy.earn(calories * _calorieToEnergyMultiplier);
  }

  void increaseEnergyMaxMultiplier(double amount) {
    energy.maxMultiplier += amount;
  }

  void increaseEnergyMaxIfBelowLimit() {
    if (energy.baseMax < 86400000) {
      // 24 hours in milliseconds
      energy.baseMax += 3600000; // 1 hour in milliseconds
    }
  }

  // Space operations
  bool canSpendSpace(double amount) {
    return space.count >= amount;
  }

  void spendSpace(double amount) {
    space.spend(amount);
  }

  double earnSpace(double amount) {
    return space.earn(amount);
  }

  void increaseSpaceMaxMultiplier(double amount) {
    space.maxMultiplier += amount;
  }
}
