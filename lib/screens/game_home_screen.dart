import 'package:flutter/material.dart';
import 'package:idlefit/helpers/constants.dart';
import 'package:idlefit/models/quest_stats.dart';
import 'package:idlefit/screens/generator_screen.dart';
import 'package:idlefit/screens/shop_screen.dart';
import 'package:idlefit/screens/stats_screen.dart';
import 'package:idlefit/services/ad_service.dart';
import 'package:idlefit/providers/game_state_provider.dart';
import 'package:idlefit/services/notification_service.dart';
import 'package:idlefit/widgets/background_earnings_popup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/main.dart';

class GameHomePage extends ConsumerStatefulWidget {
  const GameHomePage({super.key});

  @override
  ConsumerState<GameHomePage> createState() => _GameHomePageState();
}

class _GameHomePageState extends ConsumerState<GameHomePage>
    with WidgetsBindingObserver {
  int _selectedIndex = 1; // Start with main screen
  final List<Widget> _screens = [
    const StatsScreen(),
    const GeneratorsScreen(),
    const ShopScreen(),
  ];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // print("new state: $state");
    if (![
      AppLifecycleState.paused,
      AppLifecycleState.resumed,
    ].contains(state)) {
      return;
    }
    final gameStateNotifier = ref.read(gameStateProvider.notifier);

    if (state == AppLifecycleState.paused) {
      // going to background
      gameStateNotifier.setIsPaused(true);
      return;
    }
    // going to foreground
    await ref
        .read(healthServiceProvider)
        .syncHealthData(
          ref.read(gameStateProvider.notifier),
          ref.read(questStatsRepositoryProvider),
        );
    NotificationService.cancelAllNotifications();
    gameStateNotifier.setIsPaused(false);

    await Future.delayed(const Duration(milliseconds: 1200)).then((_) {
      if (!mounted) {
        return;
      }
      final gameState = ref.read(gameStateProvider);
      final backgroundActivity = gameState.backgroundActivity;

      if (backgroundActivity.energySpent < 60000) {
        // do not show popup if energy spent is less than 1 minute
        return;
      }
      // dismiss existing dialogs
      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);

      showDialog(
        context: context,
        builder:
            (context) =>
                BackgroundEarningsPopup(backgroundActivity: backgroundActivity),
      );
      gameStateNotifier.resetBackgroundActivity();
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize health data
    final healthService = ref.read(healthServiceProvider);
    final gameStateNotifier = ref.read(gameStateProvider.notifier);
    final questStatsRepository = ref.read(questStatsRepositoryProvider);
    // Initialize ads
    AdService.initialize();

    healthService.initialize().then((_) async {
      await healthService.syncHealthData(
        gameStateNotifier,
        questStatsRepository,
      );
      gameStateNotifier.setIsPaused(false);
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Constants.primaryColor,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Shop',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
