import 'package:flutter/material.dart';
import 'package:idlefit/constants.dart';
import 'package:idlefit/services/game_state_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/main_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/shop_screen.dart';
import 'services/health_service.dart';
import 'services/storage_service.dart';
import 'services/object_box.dart';
import 'widgets/background_earnings_popup.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';

// Create providers for our services
final healthServiceProvider = Provider<HealthService>((ref) => HealthService());
final objectBoxProvider = Provider<ObjectBox>(
  (ref) => throw UnimplementedError('Initialize in main'),
);
final storageServiceProvider = Provider<StorageService>(
  (ref) => throw UnimplementedError('Initialize in main'),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  final healthService = HealthService();
  final objectBox = await ObjectBox.create();

  // Initialize notifications
  await NotificationService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        // Override the providers with initialized instances
        healthServiceProvider.overrideWithValue(healthService),
        objectBoxProvider.overrideWithValue(objectBox),
        storageServiceProvider.overrideWithValue(storageService),
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
        /* dark theme settings */
      ),
      themeMode: ThemeMode.dark,
      home: const GameInitializer(),
    );
  }
}

// A widget to initialize the game state before showing the home page
class GameInitializer extends ConsumerStatefulWidget {
  const GameInitializer({super.key});

  @override
  ConsumerState<GameInitializer> createState() => _GameInitializerState();
}

class _GameInitializerState extends ConsumerState<GameInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeGameState();
  }

  Future<void> _initializeGameState() async {
    final storageService = ref.read(storageServiceProvider);
    final objectBox = ref.read(objectBoxProvider);

    // Initialize the game state
    await ref
        .read(gameStateProvider.notifier)
        .initialize(storageService, objectBox.store);

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return const GameHomePage();
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
    final gameStateNotifier = ref.read(gameStateProvider.notifier);

    if (state == AppLifecycleState.paused) {
      // going to background
      // gameStateNotifier
      gameStateNotifier.setIsPaused(true);
      // gameStateNotifier.save();
      // gameStateNotifier.saveBackgroundState();
      return;
    }
    // going to foreground
    final healthService = ref.read(healthServiceProvider);
    final objectBoxService = ref.read(objectBoxProvider);

    await healthService.syncHealthData(objectBoxService, gameStateNotifier);
    NotificationService.cancelAllNotifications();
    gameStateNotifier.setIsPaused(false);

    await Future.delayed(const Duration(seconds: 1)).then((_) {
      if (!mounted) {
        return;
      }
      final earnings = gameStateNotifier.getBackgroundDifferences();
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
    // Initialize health data
    final healthService = ref.read(healthServiceProvider);
    final gameStateNotifier = ref.read(gameStateProvider.notifier);
    final objectBoxService = ref.read(objectBoxProvider);

    // Initialize ads
    AdService.initialize();

    healthService.initialize().then((_) async {
      await healthService.syncHealthData(objectBoxService, gameStateNotifier);
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
