import 'package:flutter/material.dart';
import 'package:idlefit/helpers/constants.dart';
import 'package:idlefit/screens/generator_screen.dart';
import 'package:idlefit/screens/shop_screen.dart';
import 'package:idlefit/screens/stats_screen.dart';
import 'package:idlefit/services/ad_service.dart';
import 'package:idlefit/services/notification_service.dart';
import 'package:idlefit/widgets/background_earnings_popup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/widgets/currency_bar.dart';
import 'package:idlefit/widgets/sidebar.dart';
import 'package:idlefit/providers/providers.dart';

final sidebarProvider = StateProvider<bool>((ref) => false);

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
      ref.read(gameLoopProvider.notifier).pause();
      return;
    }

    // TODO: show dialog asking user if they want to be notified when coin capacity is reached
    // Initialize notifications

    // going to foreground
    await ref
        .read(healthServiceProvider)
        .syncHealthData(
          ref.read(gameStateProvider.notifier),
          ref.read(questStatsRepositoryProvider),
        );
    NotificationService.cancelAllNotifications();
    ref.read(gameLoopProvider.notifier).resume();

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

    healthService.initialize().then((authorized) async {
      if (authorized) {
        await healthService.syncHealthData(
          gameStateNotifier,
          questStatsRepository,
          days: 1,
        );
      }
      ref.read(gameLoopProvider.notifier).resume();
    });

    // Initialize ads
    AdService.initialize();

    // TODO: delay until after first return from background
    NotificationService.initialize();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    final isSidebarOpen = ref.watch(sidebarProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Constants.barColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: CurrencyBar(
          onMenuPressed:
              () => ref.read(sidebarProvider.notifier).state = !isSidebarOpen,
          isSidebarOpen: isSidebarOpen,
        ),
      ),
      body: Stack(
        children: [
          _screens[_selectedIndex],
          Sidebar(
            isOpen: isSidebarOpen,
            toggleSidebar:
                () => ref.read(sidebarProvider.notifier).state = false,
          ),
        ],
      ),
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
