import 'package:idlefit/repositories/currency_repo.dart';
import 'package:idlefit/models/currency.dart';

class CurrencyService {
  static const _calorieToEnergyMultiplier =
      72000.0; // 1 calorie = 72 seconds of idle fuel

  final CurrencyRepo _currencyRepo;
  late Currency _coins;
  late Currency _gems;
  late Currency _energy;
  late Currency _space;

  CurrencyService({required CurrencyRepo currencyRepo})
    : _currencyRepo = currencyRepo;

  Future<void> initialize() async {
    // Ensure default currencies exist
    _currencyRepo.ensureDefaultCurrencies();

    // Load currencies
    final currencies = _currencyRepo.loadCurrencies();
    _coins = currencies[CurrencyType.coin]!;
    _gems = currencies[CurrencyType.gem]!;
    _energy = currencies[CurrencyType.energy]!;
    _space = currencies[CurrencyType.space]!;
  }

  // Getters for currencies
  Currency get coins => _coins;
  Currency get gems => _gems;
  Currency get energy => _energy;
  Currency get space => _space;

  // Save all currencies
  void saveCurrencies() {
    _currencyRepo.saveCurrencies([_coins, _gems, _energy, _space]);
  }

  // Coin operations
  bool canSpendCoins(double amount) => _coins.count >= amount;
  void earnCoins(double amount) => _coins.earn(amount);
  bool spendCoins(double amount) => _coins.spend(amount);
  void updateCoinMax(double newMax) => _coins.baseMax = newMax;
  void increaseCoinMaxMultiplier(double multiplier) =>
      _coins.maxMultiplier += multiplier;

  // Gem operations
  bool canSpendGems(double amount) => _gems.count >= amount;
  void earnGems(double amount) => _gems.earn(amount);
  bool spendGems(double amount) => _gems.spend(amount);
  void increaseGemMax(double amount) => _gems.baseMax += amount;

  // Energy operations
  bool canSpendEnergy(double amount) => _energy.count >= amount;
  void earnEnergy(double amount) => _energy.earn(amount);
  bool spendEnergy(double amount) => _energy.spend(amount);
  void increaseEnergyMaxMultiplier(double multiplier) =>
      _energy.maxMultiplier += multiplier;
  void increaseEnergyMaxIfBelowLimit() {
    const maxEnergyHours = 24;
    const hourInMillis = 3600;
    if (_energy.baseMax < maxEnergyHours * hourInMillis) {
      _energy.baseMax += hourInMillis;
    }
  }

  // Space operations
  bool canSpendSpace(double amount) => _space.count >= amount;
  double earnSpace(double amount) {
    return _space.earn(amount);
  }

  bool spendSpace(double amount) => _space.spend(amount);
  void increaseSpaceMaxMultiplier(double multiplier) =>
      _space.maxMultiplier += multiplier;

  // Convert calories to energy
  double convertCaloriesToEnergy(double calories) {
    // 1 calorie = 1 second of energy
    final energyGained = calories;
    _energy.earn(energyGained);
    return energyGained;
  }
}
