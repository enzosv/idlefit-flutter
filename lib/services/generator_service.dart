import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/shop_items.dart';
import 'package:idlefit/models/shop_items_repo.dart';

class GeneratorService {
  List<CoinGenerator> coinGenerators = [];
  List<ShopItem> shopItems = [];

  final CoinGeneratorRepo _generatorRepo;
  final ShopItemsRepo _shopItemRepo;

  GeneratorService({
    required CoinGeneratorRepo generatorRepo,
    required ShopItemsRepo shopItemRepo,
  }) : _generatorRepo = generatorRepo,
       _shopItemRepo = shopItemRepo;

  Future<void> initialize() async {
    // Load data from repositories
    coinGenerators = await _generatorRepo.parseCoinGenerators(
      'assets/coin_generators.json',
    );
    shopItems = await _shopItemRepo.parseShopItems('assets/shop_items.json');
  }

  double getTotalPassiveOutput() {
    return coinGenerators.fold(0, (sum, generator) => sum + generator.output);
  }

  double getCoinMultiplierFromShopItems() {
    double multiplier = 0.0;
    for (final item in shopItems) {
      if (item.shopItemEffect == ShopItemEffect.coinMultiplier) {
        multiplier += item.effectValue * item.level;
      }
    }
    return multiplier;
  }

  double getHealthMultiplier() {
    double multiplier = 1.0;
    for (final item in shopItems) {
      if (item.shopItemEffect == ShopItemEffect.healthMultiplier) {
        multiplier += item.effectValue * item.level;
      }
    }
    return multiplier;
  }

  void incrementGeneratorCount(CoinGenerator generator) {
    generator.count++;
    _generatorRepo.saveCoinGenerator(generator);
  }

  void upgradeShopItem(ShopItem item) {
    item.level++;
    _shopItemRepo.saveShopItem(item);
  }

  void unlockGenerator(CoinGenerator generator) {
    generator.isUnlocked = true;
    _generatorRepo.saveCoinGenerator(generator);
  }

  void upgradeGenerator(CoinGenerator generator) {
    generator.level++;
    _generatorRepo.saveCoinGenerator(generator);
  }
}
