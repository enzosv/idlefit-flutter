import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/constants.dart';
import 'package:idlefit/providers/game_engine_provider.dart';
import 'package:idlefit/providers/objectbox_provider.dart';
import 'services/health_service.dart';
import 'screens/main_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/shop_screen.dart';
import 'services/object_box.dart';
import 'widgets/background_earnings_popup.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';

// Health service provider
final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService();
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final healthService = HealthService();
  final objectBox = await ObjectBox.create();

  // Initialize notifications
  await NotificationService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        // Override objectBoxProvider with actual instance
        objectBoxProvider.overrideWithValue(objectBox),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Idle Game',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        splashColor: Colors.transparent,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      themeMode: ThemeMode.dark,
      home: const GameHomePage(),
    );
  }
}

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
    const MainScreen(),
    const ShopScreen(),
  ];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    print("new state: $state");
    if (![
      AppLifecycleState.paused,
      AppLifecycleState.resumed,
    ].contains(state)) {
      return;
    }

    if (state == AppLifecycleState.paused) {
      // going to background
      ref.read(gameEngineProvider.notifier).setPaused(true);
      ref.read(gameEngineProvider.notifier).saveBackgroundState();
      return;
    }

    // going to foreground
    final healthService = ref.read(healthServiceProvider);
    await healthService.syncHealthData(
      ref.read(objectBoxProvider),
      ref.read(gameEngineProvider.notifier),
    );

    NotificationService.cancelAllNotifications();
    ref.read(gameEngineProvider.notifier).setPaused(false);

    await Future.delayed(const Duration(seconds: 1)).then((_) {
      if (!mounted) {
        return;
      }

      final earnings =
          ref.read(gameEngineProvider.notifier).getBackgroundDifferences();
      if ((earnings['energy_spent'] ?? 0) > 60000) {
        // do not show popup if energy spent is less than 1 minute
        showDialog(
          context: context,
          builder: (context) => BackgroundEarningsPopup(earnings: earnings),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // Initialize game engine (paused)
    ref.read(gameEngineProvider.notifier).setPaused(true);

    // Initialize ads
    AdService.initialize();

    // Initialize health data
    final healthService = ref.read(healthServiceProvider);
    healthService.initialize().then((_) async {
      await healthService.syncHealthData(
        ref.read(objectBoxProvider),
        ref.read(gameEngineProvider.notifier),
      );
      ref.read(gameEngineProvider.notifier).setPaused(false);
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
