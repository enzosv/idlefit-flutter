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
import 'package:idlefit/services/health_service.dart';
import 'package:idlefit/services/object_box.dart';
import 'package:idlefit/services/game_state.dart';

final coinProvider = StateNotifierProvider<CurrencyNotifier, Currency>((ref) {
  return CurrencyNotifier(
    ref,
    Currency(id: CurrencyType.coin.index, count: 10, baseMax: 100),
  );
});

final energyProvider = StateNotifierProvider<CurrencyNotifier, Currency>((ref) {
  return CurrencyNotifier(
    ref,
    Currency(
      id: CurrencyType.energy.index,
      count: 0,
      baseMax: 43200000, //12hrs
    ),
  );
});

final spaceProvider = StateNotifierProvider<CurrencyNotifier, Currency>((ref) {
  return CurrencyNotifier(
    ref,
    Currency(id: CurrencyType.space.index, count: 0, baseMax: 5000),
  );
});

final gemProvider = StateNotifierProvider<CurrencyNotifier, Currency>((ref) {
  return CurrencyNotifier(
    ref,
    Currency(id: CurrencyType.gem.index, count: 10, baseMax: 100),
  );
});

final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((
  ref,
) {
  return GameStateNotifier(
    ref,
    GameState(isPaused: true, lastGenerated: 0, doubleCoinExpiry: 0),
  );
});

final shopItemProvider =
    StateNotifierProvider<ShopItemNotifier, List<ShopItem>>((ref) {
      final notifier = ShopItemNotifier(
        ref.read(objectBoxProvider).store.box<ShopItem>(),
        [],
      );
      notifier.initialize();
      return notifier;
    });

final generatorProvider =
    StateNotifierProvider<CoinGeneratorNotifier, List<CoinGenerator>>((ref) {
      final notifier = CoinGeneratorNotifier(
        ref.read(objectBoxProvider).store.box<CoinGenerator>(),
        [],
      );
      notifier.initialize();
      return notifier;
    });

final currencyRepoProvider = Provider<CurrencyRepo>((ref) {
  final box = ref.read(objectBoxProvider).store.box<Currency>();
  final repo = CurrencyRepo(box: box);
  repo.initialize(ref);
  return repo;
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
