import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/models/currency_repo.dart';
import 'package:idlefit/models/quest_repo.dart';
import 'package:idlefit/models/quest_stats.dart';
import 'package:idlefit/models/shop_items.dart';
import 'package:idlefit/providers/currency_provider.dart';
import 'package:idlefit/providers/game_state_provider.dart';
import 'package:idlefit/providers/generator_provider.dart';
import 'package:idlefit/providers/shop_item_provider.dart';
import 'package:idlefit/providers/game_loop_provider.dart';
import 'package:idlefit/services/health_service.dart';
import 'package:idlefit/services/object_box.dart';
import 'package:idlefit/services/game_state.dart';

final coinProvider = NotifierProvider<CurrencyNotifier, Currency>(() {
  return CurrencyNotifier(CurrencyType.coin);
});
final spaceProvider = NotifierProvider<CurrencyNotifier, Currency>(() {
  return CurrencyNotifier(CurrencyType.space);
});
final energyProvider = NotifierProvider<CurrencyNotifier, Currency>(() {
  return CurrencyNotifier(CurrencyType.energy);
});

final shopItemProvider = NotifierProvider<ShopItemNotifier, List<ShopItem>>(() {
  return ShopItemNotifier();
});

final generatorProvider =
    NotifierProvider<CoinGeneratorNotifier, List<CoinGenerator>>(() {
      return CoinGeneratorNotifier();
    });

final currencyRepoProvider = Provider<CurrencyRepo>((ref) {
  final box = ref.read(objectBoxProvider).store.box<Currency>();
  return CurrencyRepo(box: box);
});

final questStatsRepositoryProvider = Provider<QuestStatsRepository>((ref) {
  final box = ref.read(objectBoxProvider).store.box<QuestStats>();
  return QuestStatsRepository(box);
});

final healthServiceProvider = Provider<HealthService>(
  (ref) => throw UnimplementedError('Initialize in main'),
);
final objectBoxProvider = Provider<ObjectBox>(
  (ref) => throw UnimplementedError('Initialize in main'),
);

final questRepositoryProvider = Provider<QuestRepository>((ref) {
  final box = ref.read(objectBoxProvider).store.box<Quest>();
  return QuestRepository(box);
});

final gameStateProvider = NotifierProvider<GameStateNotifier, GameState>(() {
  return GameStateNotifier();
});

final gameLoopProvider = NotifierProvider<GameLoopNotifier, void>(() {
  return GameLoopNotifier();
});
